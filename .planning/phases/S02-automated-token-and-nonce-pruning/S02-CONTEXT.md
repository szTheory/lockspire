# S02 Context: Automated Token & Nonce Pruning

## Goal
Delete expired tokens, nonces, device codes, and pushed authorization requests from the database in the background without blocking requests or causing lock contention.

## Architectural Decisions
1. **Engine**: We will use `Oban.Plugins.Cron` within Lockspire's embedded `Lockspire.Oban` instance. This ensures execution exactly once across a clustered Phoenix deployment.
2. **Batching**: Deletions will be performed using a chunked query pattern (`LIMIT 1000` expired IDs, then `Repo.delete_all(where: id in ^ids)`) recursively until 0 remain, avoiding table lock escalation.
3. **Table Scope**: A single `Lockspire.Workers.Pruner` Oban worker will sequentially execute the chunked cleanup across all 6 expiring models:
   - `Token`
   - `DpopReplay`
   - `PushedAuthorizationRequest`
   - `Interaction`
   - `DeviceAuthorization`
   - `InitialAccessToken`

## Developer Ergonomics
- The cron schedule will have a sensible default (e.g. hourly) that the host application can override via Lockspire's configuration block.
- Telemetry events will be emitted for the number of pruned records per model for observability.