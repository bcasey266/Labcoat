const express = require("express");
const fetch = require("node-fetch");

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization"
  );
  next();
});

// Get the list of teams
app.get("/teams", async (req, res) => {
  try {
    const response = await fetch(
      "https://app.terraform.io/api/v2/organizations/gjon/teams",
      {
        headers: {
          Authorization:
            "Bearer <token>",
          "Content-Type": "application/vnd.api+json",
        },
      }
    );
    const data = await response.json();
    const teamNames = data.data.map((team) => team.attributes.name);
    res.json(teamNames);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Something went wrong" });
  }
});
