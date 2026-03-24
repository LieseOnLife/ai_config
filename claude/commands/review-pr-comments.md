# Review PR Comments

Review and respond to automated PR comments (Codex, linters, etc.) on the current branch's PR.

## Usage

```
/review-pr-comments [PR_NUMBER]
```

If no PR number provided, auto-detect from current branch.

## Process

1. **Fetch PR comments** - Get all review comments from the PR
2. **Categorize commenters:**
   - **Bots** - Evaluate and respond definitively
   - **Humans** - Highlight to user with link and recommendation
3. **For each bot comment:**
   - Read the referenced code and surrounding context
   - Evaluate if the suggestion is valid/relevant
   - **Make a decision** (do NOT defer to the bot or ask questions in the PR):
     - If valid and can fix: make the edit, reply confirming fix
     - If valid but needs user input: ASK USER IN CLAUDE CODE, then reply with decision
     - If not applicable: reply explaining why
   - Reply must be definitive and state who made the decision
4. **For each human comment:**
   - Present to user in Claude Code with:
     - Direct link to comment
     - Summary of the feedback
     - Recommended action
     - Draft response for approval
5. **Commit fixes** - If edits were made, commit referencing the review
6. **Summary** - Report actions taken

## Decision Logic

When evaluating a bot suggestion:

```
1. Is the suggestion technically correct?
   - Yes → proceed to step 2
   - No → reply explaining why it's incorrect

2. Does it apply to this codebase/context?
   - Yes → proceed to step 3
   - No → reply explaining context difference

3. Can Claude implement the fix now?
   - Yes → implement fix, reply "Fixed in [commit]"
   - No (needs user input) → ASK USER IN CLAUDE CODE:
     "Bot suggested X. Options: A, B, C. Which do you prefer?"
     Then reply with chosen decision

4. Is this out of scope for current work?
   - Yes → reply "Acknowledged. Tracked for [future phase/ticket]"
   - No → implement or escalate per above
```

**IMPORTANT:** Never leave open questions in PR comments. All decisions happen in Claude Code, then a definitive answer is posted.

## Reply Format

All replies must:
1. Be definitive (no "should we...?" or "what do you think?")
2. State the decision clearly
3. Credit who made the decision
4. Sign as Claude

**Template:**
```
[Decision statement]

[Rationale if needed]

**Decision by:** [Claude / User @username via Claude Code]

---
*Comment by Claude Code*
```

## Output Format

### Human Reviews (Requires Your Attention)

```
## Human Review from @username
**Link:** https://github.com/org/repo/pull/123#discussion_r456
**File:** path/to/file.tf:42

**Comment:**
> [quoted comment text]

**Recommendation:** [Fix / Discuss / Defer / Acknowledge]
**Rationale:** [why this recommendation]

**Draft response:**
> [suggested reply text]

→ Approve this response? [Y/n/edit]
---
```

### Bot Reviews (Handled)

```
| Bot | File | Issue | Decision | By |
|-----|------|-------|----------|-----|
| Codex | cavm.tf | Missing state role | Deferred to Phase 3 | Claude |
| CodeCov | tests/ | Coverage drop | Added tests | Claude |
```

## Bot Detection

Automated reviewers (respond definitively):
- `chatgpt-codex-connector[bot]` - OpenAI Codex
- `github-actions[bot]` - GitHub Actions
- `codecov[bot]` - Coverage
- `dependabot[bot]` - Dependencies
- `sonarcloud[bot]` - Code quality
- Any user with `[bot]` suffix or `type: "Bot"`

## Example Replies

**Fixed:**
```
Fixed in commit abc123.

**Decision by:** Claude

---
*Comment by Claude Code*
```

**Deferred (Claude decided):**
```
Acknowledged. This role doesn't exist yet in customer-access org since we're bootstrapping.
Will be added in Phase 3 when state management infrastructure is set up.

**Decision by:** Claude (deferred to future phase - role prerequisite missing)

---
*Comment by Claude Code*
```

**Deferred (User decided):**
```
Acknowledged. Deferring to Phase 3 per project scope.

**Decision by:** User @saje.liese via Claude Code

---
*Comment by Claude Code*
```

**Not applicable:**
```
This doesn't apply here. The customer-access org uses a different state backend
pattern than ddog - the emissary role has direct S3 access.

**Decision by:** Claude (context difference from referenced config)

---
*Comment by Claude Code*
```
