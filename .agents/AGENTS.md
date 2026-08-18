# Project Rules

## Database Patches
- Always create **new standalone SQL patch files** (e.g. `sql/patch_referral_system_v2.sql` or timestamped/descriptive patch files) for schema, function, or policy changes instead of modifying existing monolithic patch files (`patch.sql`).
