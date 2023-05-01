import React, { useState, useEffect } from 'react';
import {
  Heading,
  useToast,
  Icon,
  Container,
  ChakraProvider,
  Box,
  FormControl,
  FormLabel,
  Input,
  InputGroup,
  InputLeftElement,
  Radio,
  RadioGroup,
  Stack,
  Button,
  VStack,
  Spinner,
  Flex,
  IconButton,
  Image,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalCloseButton,
  ModalBody,
  Text,
  Menu,
  MenuButton,
  MenuList,
  MenuItem,
  MenuDivider,
  Spacer,
} from '@chakra-ui/react';
import {
  FaDollarSign,
  FaUser,
  FaBars,
  FaDoorOpen,
  FaVectorSquare,
} from 'react-icons/fa';

import {
  AuthenticatedTemplate,
  UnauthenticatedTemplate,
  useMsal,
  useMsalAuthentication,
} from '@azure/msal-react';

import './App.css';
import './components/TableModal.js';
import TableModal from './components/TableModal.js';
/**
 * If a user is authenticated the ProfileContent component above is rendered. Otherwise a message indicating a user is not authenticated is rendered.
 */

export default function App() {
  const { login, result, error } = useMsalAuthentication('redirect');

  return (
    <div className='App'>
      <AuthenticatedTemplate>
        <ChakraProvider>
          <Box bg='gray.100' minHeight='100vh'>
            <WebForm />
          </Box>
        </ChakraProvider>
      </AuthenticatedTemplate>

      <UnauthenticatedTemplate>
        <h5>
          <center>Please sign-in to create a sandbox.</center>
        </h5>
      </UnauthenticatedTemplate>
    </div>
  );
}

const WebForm = () => {
  const toast = useToast();

  var { instance, accounts } = useMsal();
  const [ManagerEmail, setManagerEmail] = useState('');
  const [Budget, setBudget] = useState('');
  const [Length, setLength] = useState('');
  const [CostCenter, setCostCenter] = useState([]);
  const [isValid, setIsValid] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleUserIconClick = () => {
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
  };

  const [isSandboxModalOpen, setIsSandboxModalOpen] = useState(false);
  const onSandboxClose = () => setIsSandboxModalOpen(false);
  const onSandboxOpen = () => setIsSandboxModalOpen(true);

  useEffect(() => {
    if (Budget !== '' && Length !== '') {
      setIsValid(true);
    } else {
      setIsValid(false);
    }
  }, [Budget, Length]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    console.log(accounts[0]);

    const payload = {
      FirstName: accounts[0].name.split(' ')[0],
      LastName: accounts[0].name.split(' ')[1],
      Email: accounts[0].username,
      ObjectID: accounts[0].localAccountId,
      ManagerEmail,
      Budget,
      Length,
      CostCenter,
    };

    try {
      const accessTokenRequest = {
        scopes: ['User.Read'],
        account: accounts[0],
        forceRefresh: true,
      };
      instance
        .acquireTokenSilent(accessTokenRequest)
        .then(async (accessTokenResponse) => {
          // Acquire token silent success
          let accessToken = accessTokenResponse.idToken;
          console.log(accessTokenResponse);

          const response = await fetch(
            process.env.REACT_APP_api_management_name +
              '/' +
              process.env.REACT_APP_APIName +
              process.env.REACT_APP_APICreate,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: 'Bearer ' + accessToken,
              },
              body: JSON.stringify(payload),
            }
          );
          console.log(accessToken);

          if (response.ok) {
            toast({
              title: 'Submission successful',
              description: 'Your form has been submitted successfully.',
              status: 'success',
              duration: 3000,
              isClosable: true,
              position: 'top',
            });
            setIsLoading(false);
          } else {
            toast({
              title: 'Submission failed',
              description: 'There was a problem submitting your form.',
              status: 'error',
              duration: 3000,
              isClosable: true,
              position: 'top',
            });
            setIsLoading(false);
          }
        })
        .catch((error) => {
          // Handle error here
          toast({
            title: 'Submission failed',
            description: 'There was a problem submitting your form.',
            status: 'error',
            duration: 3000,
            isClosable: true,
            position: 'top',
          });
          setIsLoading(false);
        });
    } catch (error) {
      toast({
        title: 'Submission failed',
        description: 'There was a problem submitting your form.',
        status: 'error',
        duration: 3000,
        isClosable: true,
        position: 'top',
      });
      setIsLoading(false);
    }
  };

  return (
    <Container maxW='container.md' py={8}>
      <Flex bg='#3d3d3d' align='end'>
        <Box p={2}>
          <Image src='/logo.png' />
        </Box>
        <Spacer />
        <Box boxSize='110px' p={2}>
          <Image src='/Erobi.png' />
        </Box>
      </Flex>

      <Box
        bg='white'
        boxShadow='base'
        borderRadius='md'
        p={6}
        mx='auto'
        mt={0}
        width='100%'
      >
        <Flex alignItems='center' mb={4}>
          <Heading as='h1' size='lg' flex='1'>
            Sandbox Request
          </Heading>
          <Menu>
            <MenuButton
              as={IconButton}
              aria-label='Options'
              icon={<FaBars />}
              variant='outline'
            />
            <MenuList>
              <MenuItem icon={<FaUser />} onClick={handleUserIconClick}>
                {accounts[0].name}
              </MenuItem>
              <MenuDivider />
              <MenuItem icon={<FaVectorSquare />} onClick={onSandboxOpen}>
                My Sandboxes
              </MenuItem>
              <TableModal
                isOpen={isSandboxModalOpen}
                onClose={onSandboxClose}
              />
              <MenuItem
                icon={<FaDoorOpen />}
                onClick={() => instance.logoutRedirect()}
              >
                Sign Out
              </MenuItem>
            </MenuList>
          </Menu>
        </Flex>
        <form onSubmit={handleSubmit}>
          <VStack spacing={4}>
            <FormControl>
              <FormLabel>Manager Email</FormLabel>
              <InputGroup>
                <Input
                  type='string'
                  placeholder='Nick.Fury@shield.com'
                  value={ManagerEmail}
                  onChange={(e) => setManagerEmail(e.target.value)}
                />
              </InputGroup>
            </FormControl>

            <FormControl>
              <FormLabel>Budget</FormLabel>
              <InputGroup>
                <InputLeftElement pointerEvents='none'>
                  <Icon as={FaDollarSign} />
                </InputLeftElement>
                <Input
                  type='number'
                  placeholder='250'
                  value={Budget}
                  onChange={(e) => setBudget(e.target.value)}
                />
              </InputGroup>
            </FormControl>

            <FormControl>
              <FormLabel>Cost Center</FormLabel>
              <InputGroup>
                <Input
                  type='string'
                  placeholder='12345-123'
                  value={CostCenter}
                  onChange={(e) => setCostCenter(e.target.value)}
                />
              </InputGroup>
            </FormControl>

            <FormControl>
              <FormLabel>Length</FormLabel>
              <RadioGroup onChange={setLength} value={Length}>
                <Stack direction='row'>
                  <Radio value='1'>30 Days</Radio>
                  <Radio value='2'>60 Days</Radio>
                  <Radio value='3'>90 Days</Radio>
                </Stack>
              </RadioGroup>
            </FormControl>

            <Button
              type='submit'
              colorScheme='blue'
              isDisabled={!isValid || isLoading}
            >
              {isLoading ? <Spinner size='sm' mr={2} /> : null}
              Submit
            </Button>
          </VStack>
        </form>
      </Box>
      <Modal isOpen={isModalOpen} onClose={handleCloseModal}>
        <ModalOverlay
          bg='blackAlpha.300'
          backdropFilter='blur(10px) hue-rotate(90deg)'
        />
        <ModalContent>
          <ModalHeader>User Info</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <Text>
              <b>Name:</b> {accounts[0].name}
            </Text>
            <Text>
              <b>Email:</b> {accounts[0].username}
            </Text>
            <Text>
              <b>Object ID:</b> {accounts[0].localAccountId}
            </Text>
          </ModalBody>
        </ModalContent>
      </Modal>
    </Container>
  );
};
