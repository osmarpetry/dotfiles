---
name: Restatedev
description: Use when building durable AI agents, workflows, and backend services that need to survive failures, maintain state, and scale reliably. Restate handles resilience, state management, and distributed execution so you can focus on business logic.
metadata:
    mintlify-proj: restatedev
    version: "1.0"
---

# Restate Skill

## Product summary

Restate is a lightweight runtime that turns AI agents, workflows, and backend services into durable processes. It provides durable execution (automatic retry and recovery from failures), built-in state management, reliable service communication, and flow control. Services are regular applications that embed the Restate SDK (TypeScript, Java, Kotlin, Python, Go, Rust) and run on your infrastructure. The Restate Server sits in front of services as a reverse proxy, handling invocations, managing service discovery, and persisting execution journals. Deploy services to Kubernetes, serverless platforms (Lambda, Cloud Run, Vercel), or standalone. Invoke handlers over HTTP at `/restate/call/{service}/{handler}` or `/restate/send/{service}/{handler}`. Primary docs: https://docs.restate.dev

## When to use

Reach for Restate when:
- Building AI agents that need to survive crashes and maintain conversation state across restarts
- Implementing multi-step workflows (approvals, onboarding, transactions) that must complete exactly once
- Orchestrating calls across multiple microservices with automatic retries and failure handling
- Processing events with exactly-once semantics and durable state
- Running long-running operations on serverless platforms without paying for idle time
- Needing to coordinate distributed work with built-in concurrency control and flow limits
- Building stateful services that scale horizontally without managing databases for execution state

## Quick reference

### Service types

| Type | Use case | State | Concurrency | Key feature |
|------|----------|-------|-------------|-------------|
| **Basic Service** | API endpoints, ETL, sagas, background jobs | None | Unlimited parallel | Durable execution, service calls |
| **Virtual Object** | User accounts, shopping carts, agents, state machines | Persistent K/V per key | Single writer per key + concurrent readers | Built-in state, single-writer consistency |
| **Workflow** | Approvals, onboarding, multi-step processes | Persistent K/V per ID | Single `run` handler + concurrent shared handlers | Exactly-once execution, promises, lifecycle |

### Core context actions

| Action | Purpose | Example |
|--------|---------|---------|
| `ctx.run()` | Wrap non-deterministic operations (API calls, DB writes) for durability | `await ctx.run("fetch", () => fetchData())` |
| `ctx.get()` / `ctx.set()` | Read/write persistent state (Virtual Objects, Workflows only) | `await ctx.get("cart")` / `ctx.set("count", 5)` |
| `ctx.serviceClient()` | Call another service synchronously | `await ctx.serviceClient(MyService).handler(input)` |
| `ctx.serviceSendClient()` | Fire-and-forget message to another service | `ctx.serviceSendClient(MyService).handler(input)` |
| `ctx.sleep()` | Pause execution durably | `await ctx.sleep({ minutes: 5 })` |
| `ctx.signal()` | Wait for external event (Workflows) | `await ctx.signal("approval")` |

### HTTP invocation patterns

```bash
# Request-response (wait for result)
POST /restate/call/{service}/{handler}
POST /restate/call/{service}/{key}/{handler}  # Virtual Object or Workflow

# Fire-and-forget (no response)
POST /restate/send/{service}/{handler}
POST /restate/send/{service}/{key}/{handler}

# With delay
POST /restate/send/{service}/{handler}?delay=10s

# With idempotency key
-H 'Idempotency-Key: unique-key'

# With flow control scope
POST /restate/scope/{scopeKey}/call/{service}/{handler}
```

### Configuration options

| Option | Default | When to adjust |
|--------|---------|-----------------|
| `retryPolicy.maxAttempts` | 70 | Bound retries on FaaS to control costs |
| `retryPolicy.initialInterval` | 50ms | Reduce load on failing downstream services |
| `abortTimeout` | 10 minutes | Increase for long-running LLM calls or external APIs |
| `inactivityTimeout` | 1 minute | Increase for operations taking >1 minute |
| `idempotencyRetention` | 24 hours | Extend for financial transactions or critical ops |
| `workflowRetention` | 24 hours | Extend to query workflow state after completion |
| `journalRetention` | 24 hours | Extend to inspect execution history |
| `ingressPrivate` | false | Set true to block external HTTP/Kafka access |
| `enableLazyState` | false | Set true for large state entries on Lambda |

## Decision guidance

### When to use each service type

| Scenario | Choose |
|----------|--------|
| Stateless API endpoint, background job, or saga | Basic Service |
| Entity with persistent state (user, cart, agent session) | Virtual Object |
| Long-running process with interaction (approval, onboarding) | Workflow |
| Need to coordinate multiple services | Basic Service calling others via `ctx.serviceClient()` |
| Need to wait for external event mid-execution | Workflow with `ctx.signal()` or `ctx.promise()` |

### When to use request-response vs fire-and-forget

| Scenario | Use |
|----------|-----|
| Need result before continuing | `/restate/call/...` (request-response) |
| Background task, notification, analytics | `/restate/send/...` (fire-and-forget) |
| Scheduled task (e.g., reminder tomorrow) | `/restate/send/...?delay=1d` (delayed message) |

### When to configure timeouts

| Scenario | Adjust |
|----------|--------|
| LLM calls taking >1 minute | Increase `inactivityTimeout` and `abortTimeout` |
| External API calls timing out | Increase `inactivityTimeout`, tune `retryPolicy` |
| Long-running database operations | Increase `inactivityTimeout` |
| Serverless function cold starts | Increase `abortTimeout` |

## Workflow

### Typical task: Build a durable service

1. **Understand the requirement**: Identify if you need a Basic Service, Virtual Object, or Workflow based on state and execution model.

2. **Create the service definition**: Use the SDK for your language (TypeScript, Java, Python, Go, Rust).
   ```typescript
   const myService = restate.service({
     name: "MyService",
     handlers: {
       myHandler: async (ctx: restate.Context, input: MyInput) => {
         // Wrap external calls in ctx.run()
         const result = await ctx.run("step1", () => externalAPI(input));
         return result;
       },
     },
   });
   restate.serve({ services: [myService] });
   ```

3. **Wrap non-deterministic operations**: Use `ctx.run()` for API calls, database writes, or any operation that produces side effects.

4. **Add state if needed**: For Virtual Objects or Workflows, use `ctx.get()` and `ctx.set()` to manage persistent state.

5. **Configure timeouts and retries**: Set `inactivityTimeout`, `abortTimeout`, and `retryPolicy` in service options if defaults don't fit your use case.

6. **Deploy the service**: Build a Docker image and deploy to Kubernetes, serverless, or standalone. Register the endpoint with Restate:
   ```bash
   restate deployments register http://my-service:9080
   ```

7. **Invoke the handler**: Use HTTP, SDK clients, or Kafka to invoke handlers.

8. **Monitor execution**: Use the Restate UI (port 9070) to inspect invocations, view journals, and manage lifecycle.

### Typical task: Build a durable AI agent

1. **Create a Virtual Object** to represent the agent session, keyed by conversation ID.

2. **Wrap LLM calls in `ctx.run()`**: Persist each LLM call and tool execution.
   ```typescript
   const response = await ctx.run("llm-call", () => 
     openai.chat.completions.create({ messages, model: "gpt-4" })
   );
   ```

3. **Store conversation state**: Use `ctx.set("messages", messages)` to persist the conversation history.

4. **Implement tool execution**: Wrap tool calls in `ctx.run()` and use `ctx.serviceClient()` to call other services.

5. **Handle long operations**: Increase `inactivityTimeout` and `abortTimeout` for LLM calls that take >1 minute.

6. **Add human approval if needed**: Use `ctx.signal()` or `ctx.promise()` to pause and wait for human input.

## Common gotchas

- **Forgetting `ctx.run()` for external calls**: Non-deterministic operations (API calls, DB writes, random numbers) must be wrapped in `ctx.run()` or they will produce different results on replay, breaking recovery. Always wrap side-effecting operations.

- **Storing state in service memory**: Virtual Objects and Workflows store state in Restate's embedded K/V store, not in your service process. Your service is stateless and can crash without losing state. Don't try to maintain state in memory.

- **Resubmitting the same workflow**: Workflows run exactly once per ID. Resubmitting the same workflow ID will fail with "Previously accepted". Use a unique workflow ID per execution.

- **Timeout too short for LLM calls**: Default `inactivityTimeout` is 1 minute. LLM calls often take longer. Increase `inactivityTimeout` and `abortTimeout` to match your expected operation duration.

- **Not registering the deployment**: After deploying your service, you must register the endpoint with Restate using `restate deployments register http://service:9080`. Without registration, Restate won't know about your service.

- **Mixing deterministic and non-deterministic code**: Code inside `ctx.run()` must be deterministic on replay (same input = same output). Don't use random numbers, timestamps, or external state inside `ctx.run()` without wrapping them in another `ctx.run()`.

- **Ignoring flow control for expensive operations**: If you have expensive operations (LLM calls, API calls), use flow control scopes to limit concurrency and control costs. Add `scope/{scopeKey}` to your invocation URL.

- **Lazy state on non-FaaS platforms**: `enableLazyState` is only beneficial on serverless platforms (Lambda, Cloud Run) where replay is expensive. On Kubernetes, eager state (default) is faster.

## Verification checklist

Before submitting work with Restate:

- [ ] All external API calls, database operations, and side effects are wrapped in `ctx.run()`
- [ ] Service is deployed and endpoint is registered with `restate deployments register`
- [ ] Timeouts (`inactivityTimeout`, `abortTimeout`) are set appropriately for your operation duration
- [ ] Retry policy is configured if you need to bound attempts (especially on FaaS)
- [ ] State is persisted using `ctx.set()` for Virtual Objects and Workflows (not in service memory)
- [ ] Workflow IDs are unique per execution (not reusing the same ID)
- [ ] Idempotency keys are used for critical operations that must not duplicate
- [ ] Flow control scopes are configured for expensive operations
- [ ] Service configuration (retries, timeouts, retention) matches your SLA requirements
- [ ] Invocation URLs use `/restate/call/` or `/restate/send/` paths (not legacy unversioned paths)
- [ ] Handler input/output types are JSON-serializable (or use custom serialization)
- [ ] Execution journals are inspected in the UI to verify durable steps are recorded

## Resources

- **Comprehensive page listing**: https://docs.restate.dev/llms.txt
- **Key Concepts**: https://docs.restate.dev/foundations/key-concepts
- **Services & Handlers**: https://docs.restate.dev/foundations/services
- **HTTP Invocation**: https://docs.restate.dev/services/invocation/http
- **Service Configuration**: https://docs.restate.dev/services/configuration
- **AI Agents Guide**: https://docs.restate.dev/ai
- **SDK Documentation**: TypeScript (https://docs.restate.dev/develop/ts/services), Java (https://docs.restate.dev/develop/java/services), Python (https://docs.restate.dev/develop/python/services), Go (https://docs.restate.dev/develop/go/services)

---

> For additional documentation and navigation, see: https://docs.restate.dev/llms.txt