# Expected Findings: find-right-template

## Problem Summary
User has a vague requirement ("real-time web app with server push") and needs help finding the right template. The agent should search, compare options, and make a recommendation.

## Expected Findings

### Template Discovery
- **Primary match**: Blazor Server or Blazor Web App (server-side rendering with SignalR)
- **Alternative**: ASP.NET Core Web App with SignalR (webapp or webapi + SignalR)
- **Should mention**: SignalR as the server push technology in .NET

### Search and Comparison
- Agent should search available templates, not just guess from memory
- Should present multiple options with pros/cons or descriptions
- Should explain why each option fits (or doesn't fit) the "real-time server push" requirement

### Recommendation Quality
- Clear recommendation with justification
- Explains what SignalR provides (WebSocket-based real-time communication)
- Considers Blazor Server vs Blazor WebAssembly trade-offs for real-time scenarios
- Mentions that Blazor Server maintains a persistent SignalR connection by design

### Template Details
- Should inspect the recommended template to show available parameters
- Should mention framework targeting options
- Should note authentication options if relevant

## Evaluation Checklist
Award 1 point for each item correctly identified and addressed:

- [ ] Searched for available templates (not just guessed)
- [ ] Identified Blazor Server or Blazor Web App as a strong candidate
- [ ] Mentioned SignalR as the .NET real-time technology
- [ ] Presented multiple template options (not just one)
- [ ] Explained why each option fits the real-time requirement
- [ ] Made a clear recommendation with justification
- [ ] Showed template parameters or inspection details
- [ ] Mentioned framework targeting (net9.0/net10.0)
- [ ] Response is structured and easy to follow
- [ ] Information is accurate and up-to-date (not hallucinated template names)

Total: __/10

## Expected Skills/Tools
- template_search or template_list
- template_inspect
- template_from_intent (optional)
