import React, { useState, useEffect } from "react";
import {
  Heading,
  useToast,
  TagCloseButton,
  Icon,
  Tag,
  TagLabel,
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
  HStack,
} from "@chakra-ui/react";
import { FaDollarSign } from "react-icons/fa";

const App = () => {
  return (
    <ChakraProvider>
      <Box bg="gray.100" minHeight="100vh">
        <WebForm />
      </Box>
    </ChakraProvider>
  );
};

const WebForm = () => {
  const toast = useToast();
  const [budget, setBudget] = useState("");
  const [length, setLength] = useState("");
  const [tags, setTags] = useState([]);
  const [newTagKey, setNewTagKey] = useState("");
  const [newTagValue, setNewTagValue] = useState("");
  const [isValid, setIsValid] = useState(false);

  useEffect(() => {
    if (budget !== "" && tags.length > 0 && length !== "") {
      setIsValid(true);
    } else {
      setIsValid(false);
    }
  }, [budget, tags]);

  const handleSubmit = async (e) => {
    e.preventDefault();

    const payload = {
      budget,
      length,
      tags,
    };

    try {
      const response = await fetch("http://example.com", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        toast({
          title: "Submission successful",
          description: "Your form has been submitted successfully.",
          status: "success",
          duration: 3000,
          isClosable: true,
          position: "top",
        });
      } else {
        toast({
          title: "Submission failed",
          description: "There was a problem submitting your form.",
          status: "error",
          duration: 3000,
          isClosable: true,
          position: "top",
        });
      }
    } catch (error) {
      toast({
        title: "Submission failed",
        description: "There was a problem submitting your form. ",
        status: "error",
        duration: 3000,
        isClosable: true,
        position: "top",
      });
    }
  };

  const handleAddTag = () => {
    setTags([...tags, { [newTagKey]: newTagValue }]);
    setNewTagKey("");
    setNewTagValue("");
  };

  return (
    <Container maxW="container.md" py={8}>
      <Box
        bg="white"
        boxShadow="base"
        borderRadius="md"
        p={6}
        mx="auto"
        mt={4}
        width="100%"
      >
        <form onSubmit={handleSubmit}>
          <VStack spacing={4}>
            <Heading as="h1" size="lg">
              Sandbox Request
            </Heading>
            <FormControl>
              <FormLabel>Budget</FormLabel>
              <InputGroup>
                <InputLeftElement pointerEvents="none">
                  <Icon as={FaDollarSign} />
                </InputLeftElement>
                <Input
                  type="number"
                  placeholder="Budget"
                  value={budget}
                  onChange={(e) => setBudget(e.target.value)}
                />
              </InputGroup>
            </FormControl>

            <FormControl>
              <FormLabel>Length</FormLabel>
              <RadioGroup onChange={setLength} value={length}>
                <Stack direction="row">
                  <Radio value="30">30</Radio>
                  <Radio value="60">60</Radio>
                  <Radio value="90">90</Radio>
                </Stack>
              </RadioGroup>
            </FormControl>

            <FormControl>
              <FormLabel>Tags</FormLabel>
              <VStack spacing={2}>
                {tags.map((tag, index) => {
                  const [key, value] = Object.entries(tag)[0];
                  return (
                    <Tag
                      key={index}
                      borderRadius="full"
                      variant="solid"
                      colorScheme="blue"
                      size="md"
                    >
                      <TagLabel>{key}</TagLabel>: {value}
                      <TagCloseButton
                        colorScheme="red"
                        onClick={() => {
                          const newTags = [...tags];
                          newTags.splice(index, 1);
                          setTags(newTags);
                        }}
                      />
                    </Tag>
                  );
                })}
                <HStack spacing={4}>
                  <Input
                    placeholder="Tag Key"
                    value={newTagKey}
                    onChange={(e) => setNewTagKey(e.target.value)}
                  />
                  <Input
                    placeholder="Tag Value"
                    value={newTagValue}
                    onChange={(e) => setNewTagValue(e.target.value)}
                  />
                  <Button onClick={handleAddTag}>Add</Button>
                </HStack>
              </VStack>
            </FormControl>

            <Button type="submit" colorScheme="blue" isDisabled={!isValid}>
              Submit
            </Button>
          </VStack>
        </form>
      </Box>
    </Container>
  );
};

export default App;
