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
    {
      // Personal GitHub org/user (repos, PRs, issues); GitHub owner names are case-insensitive.
      match: (url) => url.hostname === "github.com" && /^\/lieseonlife(\/|$)/i.test(url.pathname),
      open: { name: "Google Chrome", profile: "Your Chrome" },
    },
  ],
};
