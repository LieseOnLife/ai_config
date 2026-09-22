module.exports = {
  default: { name: "Google Chrome", profile: "Default" },
  rules: [
    {
      match: domain(
        "ddog-gov.com",
        "fed.dog",
        "amazonaws-us-gov.com",
        "d-9067f50546.awsapps.com",
      ),
      open: { name: "Google Chrome", profile: "Profile 3" },
    },
  ],
};
