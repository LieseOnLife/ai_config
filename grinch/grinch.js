module.exports = {
  default: { name: "Google Chrome", profile: "Default" },
  rules: [
    {
      match: domain("ddog-gov.com", "fed.dog"),
      open: { name: "Google Chrome", profile: "Profile 3" },
    },
  ],
};
