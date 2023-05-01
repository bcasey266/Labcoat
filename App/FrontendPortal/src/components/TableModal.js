// TableModal.js
import React, { useState, useEffect } from 'react';
import { useMsal, useIsAuthenticated } from '@azure/msal-react';
import { InteractionRequiredAuthError } from '@azure/msal-browser';
import { loginRequest } from '../authConfig';

import {
  Button,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalCloseButton,
  ModalBody,
  ModalFooter,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  Box,
  IconButton,
  Flex,
  Spinner,
  Tooltip,
  useToast,
} from '@chakra-ui/react';

import { DeleteIcon, RepeatIcon, LinkIcon } from '@chakra-ui/icons';
import AlertDialogWithActions from './AlertDialog';

const fieldsToDisplay = [
  'RowKey',
  'ManagerEmail',
  'Budget',
  'CostCenter',
  'EndDate',
  'Status',
];

const TableModal = ({ isOpen, onClose }) => {
  const { instance, accounts } = useMsal();
  const [isDeleteOpen, setisDeleteOpen] = React.useState(false);
  const [isResetOpen, setisResetOpen] = React.useState(false);
  const [selectedSandbox, setSelectedSandbox] = React.useState(null);
  const toast = useToast();
  const [showActiveOnly, setShowActiveOnly] = useState(
    localStorage.getItem('showActiveOnly') === 'true' ? true : false
  );
  const isAuthenticated = useIsAuthenticated();
  const [sandboxes, setSandboxes] = useState([]);
  const [loading, setLoading] = useState(true);

  const handleDeleteClick = (sandbox) => {
    setSelectedSandbox(sandbox);
    setisDeleteOpen(true);
  };

  const handleResetClick = (sandbox) => {
    setSelectedSandbox(sandbox);
    setisResetOpen(true);
  };

  const handleDeleteConfirmClose = () => {
    setisDeleteOpen(false);
  };

  const handleResetConfirmClose = () => {
    setisResetOpen(false);
  };

  const handleDeleteSandbox = async () => {
    try {
      await sandboxAction(
        selectedSandbox.RowKey,
        process.env.REACT_APP_APIDelete
      );
      handleDeleteConfirmClose();
      toast({
        title: 'Submission Received',
        description: `Sandbox ${selectedSandbox.RowKey} has been queued for deletion.`,
        status: 'success',
        duration: 5000,
        isClosable: true,
      });
    } catch (error) {
      toast({
        title: 'Deletion Failed',
        description: `Error deleting sandbox ${selectedSandbox.RowKey}. Please try again.`,
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const handleResetSandbox = async () => {
    try {
      await sandboxAction(
        selectedSandbox.RowKey,
        process.env.REACT_APP_APIReset
      );
      toast({
        title: 'Submission Received',
        description: `Sandbox ${selectedSandbox.RowKey} has been queued for reset.`,
        status: 'success',
        duration: 5000,
        isClosable: true,
      });
    } catch (error) {
      toast({
        title: 'Deletion Failed',
        description: `Error resetting sandbox ${selectedSandbox.RowKey}. Please try again.`,
        status: 'error',
        duration: 5000,
        isClosable: true,
      });
    }
  };

  const handleLink = (sandbox) => {
    setSelectedSandbox(sandbox);
    const url = `https://portal.azure.com/#@/resource/subscriptions/${process.env.REACT_APP_SandboxSubscription}/resourceGroups/${sandbox.RowKey}/overview`;
    window.open(url, '_blank');
  };

  const headers = [...fieldsToDisplay, 'Reset', 'Delete', 'Browse'].map(
    (header) => {
      if (header === 'RowKey') {
        return 'Sandbox Name';
      } else if (header === 'ManagerEmail') {
        return 'Manager Email';
      } else if (header === 'CostCenter') {
        return 'Cost Center';
      } else if (header === 'EndDate') {
        return 'End Date';
      } else {
        return header;
      }
    }
  );

  const filteredData = showActiveOnly
    ? sandboxes.filter((item) => item.Status === 'Active')
    : sandboxes;

  useEffect(() => {
    localStorage.setItem('showActiveOnly', showActiveOnly);
  }, [showActiveOnly]);

  useEffect(() => {
    if (isAuthenticated && isOpen) {
      async function getSandboxes() {
        try {
          const accessToken = await instance.acquireTokenSilent({
            ...loginRequest,
            account: accounts[0],
            forceRefresh: true,
          });
          const fetchedSanboxes = await fetchSandboxes(accessToken.idToken);
          setSandboxes(fetchedSanboxes);
          setLoading(false);
        } catch (error) {
          if (error instanceof InteractionRequiredAuthError) {
            try {
              await instance.acquireTokenRedirect(loginRequest);
              getSandboxes();
            } catch (error) {
              console.error('Error acquiring token:', error);
            }
          } else {
            console.error('Error fetching users:', error);
          }
        }
      }
      getSandboxes();
    }
  }, [instance, isAuthenticated, accounts, isOpen]);

  async function fetchSandboxes(accessToken) {
    const endpoint = `${process.env.REACT_APP_api_management_name}/${process.env.REACT_APP_APIName}/${process.env.REACT_APP_APIList}?ObjectID=${accounts[0].localAccountId}`;
    const headers = new Headers();
    headers.append('Authorization', `Bearer ${accessToken}`);
    const response = await fetch(endpoint, { headers });
    if (!response.ok) {
      throw new Error(`Error fetching users: ${response.statusText}`);
    }

    var data = await response.json();
    if (!Array.isArray(data)) {
      data = [data];
    }

    return data;
  }

  async function sandboxAction(sandboxName, action) {
    try {
      const accessToken = await instance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0],
        forceRefresh: true,
      });
      const endpoint = `${process.env.REACT_APP_api_management_name}/${process.env.REACT_APP_APIName}${action}`;
      const headers = new Headers();
      headers.append('Authorization', `Bearer ${accessToken.idToken}`);
      headers.append('Content-Type', 'application/json');

      console.log('Sandbox Name:', sandboxName);
      console.log('Object ID:', accounts[0].localAccountId);

      const requestBody = {
        SandboxName: sandboxName,
        ObjectID: accounts[0].localAccountId,
      };

      console.log('Request Body:', JSON.stringify(requestBody));
      console.log('ID Token:', accessToken.idToken);

      const requestOptions = {
        method: 'POST',
        headers: headers,
        body: JSON.stringify(requestBody),
      };

      return new Promise(async (resolve, reject) => {
        try {
          const response = await fetch(endpoint, requestOptions);
          if (!response.ok) {
            throw new Error(`Error ${action} sandbox: ${response.statusText}`);
          }

          const data = await response.text();
          resolve(data);
        } catch (error) {
          if (error instanceof InteractionRequiredAuthError) {
            try {
              await instance.acquireTokenRedirect(loginRequest);
              sandboxAction();
            } catch (error) {
              reject(new Error(`Error acquiring token`, error));
            }
          } else {
            reject(new Error(`${action} failed: ${error}`));
          }
        }
      });
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        try {
          await instance.acquireTokenRedirect(loginRequest);
          sandboxAction();
        } catch (error) {
          throw new Error(`Error acquiring token`, error);
        }
      } else {
        throw new Error(`${action} failed: ${error}`);
      }
    }
  }

  return (
    <>
      <Modal isOpen={isOpen} onClose={onClose} size='xl'>
        <ModalOverlay
          bg='blackAlpha.300'
          backdropFilter='blur(10px) hue-rotate(90deg)'
        />
        <ModalContent maxWidth='90vw' minWidth='60vw' width='auto'>
          <ModalHeader>My Sandboxes</ModalHeader>
          <ModalCloseButton />
          <ModalBody maxHeight='70vh'>
            <Flex justifyContent='flex-end'>
              <Button onClick={() => setShowActiveOnly(!showActiveOnly)}>
                {showActiveOnly ? 'Show All' : 'Show Active Only'}
              </Button>
            </Flex>
            <Box maxHeight='70vh' overflowY='auto'>
              {!loading ? (
                <Table variant='simple'>
                  <Thead>
                    <Tr>
                      {headers.map((header) => (
                        <Th key={header}>{header}</Th>
                      ))}
                    </Tr>
                  </Thead>
                  <Tbody>
                    {filteredData.map((item, index) => (
                      <Tr key={index}>
                        {fieldsToDisplay.map((field) => (
                          <Td
                            key={field}
                            color={
                              field === 'Status'
                                ? item[field] === 'Active'
                                  ? 'green.500'
                                  : item[field] === 'Deleted'
                                  ? 'red.500'
                                  : item[field] === 'Creating'
                                  ? 'orange.500'
                                  : item[field] === 'Deleting'
                                  ? 'orange.500'
                                  : item[field] === 'Resetting'
                                  ? 'orange.500'
                                  : null
                                : null
                            }
                          >
                            {field === 'Budget'
                              ? new Intl.NumberFormat('en-US', {
                                  style: 'currency',
                                  currency: 'USD',
                                  maximumFractionDigits: 0,
                                }).format(item[field])
                              : field === 'RowKey'
                              ? item['RowKey']
                              : item[field]}
                          </Td>
                        ))}
                        <Td>
                          <Flex justifyContent='center'>
                            <Box>
                              {item.Status === 'Resetting' ? (
                                <Spinner size='sm' />
                              ) : (
                                <Tooltip
                                  label='Reset Sandbox'
                                  aria-label='Reset Sandbox'
                                  openDelay={500}
                                >
                                  <IconButton
                                    aria-label='Reset Sandbox'
                                    icon={<RepeatIcon />}
                                    size='sm'
                                    onClick={() => handleResetClick(item)}
                                    isDisabled={item.Status !== 'Active'}
                                  />
                                </Tooltip>
                              )}
                            </Box>
                          </Flex>
                        </Td>
                        <Td>
                          <Flex justifyContent='center'>
                            <Box>
                              {item.Status === 'Deleting' ? (
                                <Spinner size='sm' />
                              ) : (
                                <Tooltip
                                  label='Delete Sandbox'
                                  aria-label='Delete Sandbox'
                                  openDelay={500}
                                >
                                  <IconButton
                                    aria-label='Delete Sandbox'
                                    icon={<DeleteIcon />}
                                    size='sm'
                                    onClick={() => handleDeleteClick(item)}
                                    isDisabled={item.Status !== 'Active'}
                                  />
                                </Tooltip>
                              )}
                            </Box>
                          </Flex>
                        </Td>
                        <Td>
                          <Flex justifyContent='center'>
                            <Tooltip
                              label='View Sandbox'
                              aria-label='View Sandbox'
                              openDelay={500}
                            >
                              <IconButton
                                icon={<LinkIcon />}
                                size='sm'
                                onClick={() => handleLink(item)}
                                isDisabled={item.Status !== 'Active'}
                              />
                            </Tooltip>
                          </Flex>
                        </Td>
                      </Tr>
                    ))}
                  </Tbody>
                </Table>
              ) : (
                <Flex justifyContent='center' alignItems='center' height='25vh'>
                  <Spinner />
                </Flex>
              )}
            </Box>
          </ModalBody>
          <ModalFooter>
            <Button colorScheme='blue' mr={3} onClick={onClose}>
              Close
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
      <AlertDialogWithActions
        isOpen={isDeleteOpen}
        onClose={handleDeleteConfirmClose}
        actionName='Delete'
        onAction={() => handleDeleteSandbox(selectedSandbox)}
        title='Delete Sandbox'
        message={`Are you sure you want to delete ${selectedSandbox?.RowKey}?`}
      />
      <AlertDialogWithActions
        isOpen={isResetOpen}
        onClose={handleResetConfirmClose}
        actionName='Reset'
        onAction={() => handleResetSandbox(selectedSandbox)}
        title='Reset Sandbox'
        message={`Are you sure you want to reset ${selectedSandbox?.RowKey}?`}
      />
    </>
  );
};

export default TableModal;
