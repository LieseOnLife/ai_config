module.exports = {
  default: { name: "Google Chrome", profile: "datadoghq.com" },
  rules: [
    {
      match: domain(
        "ddog-gov.com",
        "fed.dog",
        "amazonaws-us-gov.com",
        "d-9067f50546.awsapps.com",
      ),
      open: { name: "Google Chrome", profile: "ddog-gov.com" },
    },
  ],
};
