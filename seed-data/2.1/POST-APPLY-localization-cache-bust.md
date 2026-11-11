# Localization cache bust (REQUIRED after any localization seed)

egov-localization caches messages in Redis (`redis.backbone`) under two hashes,
`messages` and `computedMessages`. These **survive pod restarts**, so DB inserts
(seed files 05/10/12) are NOT served until the cache is busted.

After applying any localization seed, run:

    kubectl exec -n backbone $(kubectl get pods -n backbone -l app=redis -o name | head -1 | cut -d/ -f2) \
      -- redis-cli DEL messages computedMessages

Then the API serves the new keys immediately (no restart needed). Browsers must
still Clear-site-data (IndexedDB/localforage caches per module, 24h TTL).
