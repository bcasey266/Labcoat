// TableModal.js
import React, { useState, useEffect } from "react";
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
} from "@chakra-ui/react";

import { DeleteIcon, RepeatIcon, LinkIcon } from "@chakra-ui/icons";
import AlertDialogWithActions from "./AlertDialog";

const data = [
  {
    Status: "Active",
    SandboxName: "Sandbox-Brandon-Casey-10",
    User: "brandon.casey@ahead.com",
    ManagerEmail: "asdfasdfas",
    Budget: "456546",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    CreationDate: "2023-04-11",
    CostCenter: "45645",
    EndDate: "2023-04-14",
    LastName: "Casey",
    FirstName: "Brandon",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-10",
    TableTimestamp: "2023-04-11T15:25:13.2833016-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A25%3A13.2833016Z'\"",
  },
  {
    Status: "Active",
    SandboxName: "Sandbox-Brandon-Casey-11",
    User: "brandon.casey@ahead.com",
    ManagerEmail: "dfgddvfdf",
    Budget: "456456",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    CreationDate: "2023-04-11",
    CostCenter: "456456",
    EndDate: "2023-04-13",
    LastName: "Casey",
    FirstName: "Brandon",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-11",
    TableTimestamp: "2023-04-11T15:30:35.3330604-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A30%3A35.3330604Z'\"",
  },
  {
    Status: "Disabled",
    Budget: "345345",
    SandboxName: "Sandbox-Brandon-Casey-12",
    ManagerEmail: "456345",
    EndDate: "2023-04-14",
    CostCenter: "345",
    User: "brandon.casey@ahead.com",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    FirstName: "Brandon",
    LastName: "Casey",
    CreationDate: "2023-04-11",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-12",
    TableTimestamp: "2023-04-11T15:53:34.9777816-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A53%3A34.9777816Z'\"",
  },
  {
    Status: "Deleting",
    Budget: "345",
    SandboxName: "Sandbox-Brandon-Casey-13",
    ManagerEmail: "xcvxcvzxc",
    EndDate: "2023-04-14",
    CostCenter: "345",
    User: "brandon.casey@ahead.com",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    FirstName: "Brandon",
    LastName: "Casey",
    CreationDate: "2023-04-11",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-13",
    TableTimestamp: "2023-04-11T15:53:49.4545295-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A53%3A49.4545295Z'\"",
  },
  {
    Status: "Active",
    Budget: "345345",
    SandboxName: "Sandbox-Brandon-Casey-14",
    ManagerEmail: "456345",
    EndDate: "2023-04-14",
    CostCenter: "345",
    User: "brandon.casey@ahead.com",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    FirstName: "Brandon",
    LastName: "Casey",
    CreationDate: "2023-04-11",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-14",
    TableTimestamp: "2023-04-11T15:53:58.635297-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A53%3A58.635297Z'\"",
  },
  {
    Status: "Active",
    SandboxName: "Sandbox-Brandon-Casey-8",
    User: "brandon.casey@ahead.com",
    ManagerEmail: "cfvbsfgdvh",
    Budget: "3245",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    CreationDate: "2023-04-11",
    CostCenter: "345",
    EndDate: "2023-04-14",
    LastName: "Casey",
    FirstName: "Brandon",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-8",
    TableTimestamp: "2023-04-11T15:15:21.8050082-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A15%3A21.8050082Z'\"",
  },
  {
    Status: "Active",
    SandboxName: "Sandbox-Brandon-Casey-9",
    User: "brandon.casey@ahead.com",
    ManagerEmail: "asdfasdfas",
    Budget: "456546",
    ObjectID: "4799ae0e-87d1-4dfb-93ec-db7253a00da2",
    CreationDate: "2023-04-11",
    CostCenter: "45645",
    EndDate: "2023-04-14",
    LastName: "Casey",
    FirstName: "Brandon",
    PartitionKey: "Sandbox",
    RowKey: "Sandbox-Brandon-Casey-9",
    TableTimestamp: "2023-04-11T15:24:56.9276971-04:00",
    Etag: "W/\"datetime'2023-04-11T19%3A24%3A56.9276971Z'\"",
  },
];

const fieldsToDisplay = [
  "SandboxName",
  "ManagerEmail",
  "Budget",
  "CostCenter",
  "CreationDate",
  "EndDate",
  "Status",
];

const TableModal = ({ isOpen, onClose }) => {
  const [isDeleteOpen, setisDeleteOpen] = React.useState(false);
  const [isResetOpen, setisResetOpen] = React.useState(false);
  const [selectedSandbox, setSelectedSandbox] = React.useState(null);
  const toast = useToast();
  const [showActiveOnly, setShowActiveOnly] = useState(
    localStorage.getItem("showActiveOnly") === "true" ? true : false
  );

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

  const handleDeleteSandbox = () => {
    console.log("Deleting sandbox:", selectedSandbox.SandboxName);
    // Add delete logic here
    handleDeleteConfirmClose();
    toast({
      title: "Submission Received",
      description: `Sandbox ${selectedSandbox.SandboxName} has been queued for deletion.`,
      status: "success",
      duration: 5000,
      isClosable: true,
    });
  };

  const handleResetSandbox = () => {
    console.log("Resetting sandbox:", selectedSandbox.SandboxName);
    // Add reset logic here
    handleResetConfirmClose();
    toast({
      title: "Submission Received",
      description: `Sandbox ${selectedSandbox.SandboxName} has been queued for reset.`,
      status: "success",
      duration: 5000,
      isClosable: true,
    });
  };

  const handleLink = (sandbox) => {
    setSelectedSandbox(sandbox);
    const url = `https://portal.azure.com/#@aheadbrandoncasey.onmicrosoft.com/resource/subscriptions/4781d26e-b7b3-49ea-b5c4-5a001c9cf167/resourceGroups/${sandbox.SandboxName}/overview`;
    window.open(url, "_blank");
  };

  const headers = [...fieldsToDisplay, "Reset", "Delete", "Browse"];

  const filteredData = showActiveOnly
    ? data.filter((item) => item.Status === "Active")
    : data;

  useEffect(() => {
    localStorage.setItem("showActiveOnly", showActiveOnly);
  }, [showActiveOnly]);

  return (
    <>
      <Modal isOpen={isOpen} onClose={onClose} size="xl">
        <ModalOverlay
          bg="blackAlpha.300"
          backdropFilter="blur(10px) hue-rotate(90deg)"
        />
        <ModalContent maxWidth="90vw" width="auto">
          <ModalHeader>My Sandboxes</ModalHeader>
          <ModalCloseButton />
          <ModalBody maxHeight="70vh">
            <Flex justifyContent="flex-end">
              <Button onClick={() => setShowActiveOnly(!showActiveOnly)}>
                {showActiveOnly ? "Show All" : "Show Active Only"}
              </Button>
            </Flex>
            <Box maxHeight="70vh" overflowY="auto">
              <Table variant="simple">
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
                            field === "Status"
                              ? item[field] === "Active"
                                ? "green.500"
                                : item[field] === "Disabled"
                                ? "red.500"
                                : item[field] === "Deleting"
                                ? "orange.500"
                                : item[field] === "Resetting"
                                ? "orange.500"
                                : null
                              : null
                          }
                        >
                          {field === "Budget"
                            ? new Intl.NumberFormat("en-US", {
                                style: "currency",
                                currency: "USD",
                              }).format(item[field])
                            : item[field]}
                        </Td>
                      ))}
                      <Td>
                        <Flex justifyContent="center">
                          <Box>
                            {item.Status === "Resetting" ? (
                              <Spinner size="sm" />
                            ) : (
                              <Tooltip
                                label="Reset Sandbox"
                                aria-label="Reset Sandbox"
                                openDelay={500}
                              >
                                <IconButton
                                  aria-label="Reset Sandbox"
                                  icon={<RepeatIcon />}
                                  size="sm"
                                  onClick={() => handleResetClick(item)}
                                />
                              </Tooltip>
                            )}
                          </Box>
                        </Flex>
                      </Td>
                      <Td>
                        <Flex justifyContent="center">
                          <Box>
                            {item.Status === "Deleting" ? (
                              <Spinner size="sm" />
                            ) : (
                              <Tooltip
                                label="Delete Sandbox"
                                aria-label="Delete Sandbox"
                                openDelay={500}
                              >
                                <IconButton
                                  aria-label="Delete Sandbox"
                                  icon={<DeleteIcon />}
                                  size="sm"
                                  onClick={() => handleDeleteClick(item)}
                                  isDisabled={item.Status !== "Active"}
                                />
                              </Tooltip>
                            )}
                          </Box>
                        </Flex>
                      </Td>
                      <Td>
                        <Flex justifyContent="center">
                          <Tooltip
                            label="View Sandbox"
                            aria-label="View Sandbox"
                            openDelay={500}
                          >
                            <IconButton
                              icon={<LinkIcon />}
                              size="sm"
                              onClick={() => handleLink(item)}
                              isDisabled={item.Status !== "Active"}
                            />
                          </Tooltip>
                        </Flex>
                      </Td>
                    </Tr>
                  ))}
                </Tbody>
              </Table>
            </Box>
          </ModalBody>
          <ModalFooter>
            <Button colorScheme="blue" mr={3} onClick={onClose}>
              Close
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
      <AlertDialogWithActions
        isOpen={isDeleteOpen}
        onClose={handleDeleteConfirmClose}
        actionName="Delete"
        onAction={() => handleDeleteSandbox(selectedSandbox)}
        title="Delete Sandbox"
        message={`Are you sure you want to delete ${selectedSandbox?.SandboxName}?`}
      />
      <AlertDialogWithActions
        isOpen={isResetOpen}
        onClose={handleResetConfirmClose}
        actionName="Reset"
        onAction={() => handleResetSandbox(selectedSandbox)}
        title="Reset Sandbox"
        message={`Are you sure you want to reset ${selectedSandbox?.SandboxName}?`}
      />
    </>
  );
};

export default TableModal;
