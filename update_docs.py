import re

with open('.planning/PROJECT.md', 'r') as f:
    project = f.read()

# Update Current State
project = re.sub(
    r'Lockspire has now archived five planning milestones\.',
    'Lockspire has now archived six planning milestones.',
    project
)
project = re.sub(
    r'Phase 26 complete — implemented RFC 7591 intake and RFC 7592 management\.',
    'v1.5 delivered Dynamic Client Registration (DCR) RFC 7591/7592 with operator policy controls, Initial Access Tokens, and truthful discovery without widening the embedded-library shape.',
    project
)

# Remove Current Milestone section
project = re.sub(
    r'## Current Milestone: v1\.5 Dynamic Client Registration.*?(?=## Requirements)',
    '',
    project,
    flags=re.DOTALL
)

# Move Active requirements to Validated
project = re.sub(
    r'### Active.*?### Out of Scope',
    '### Active\n\n(None currently)\n\n### Out of Scope',
    project,
    flags=re.DOTALL
)
validated_addition = """- Deliver RFC 7591 `POST /register` intake bounded by operator policy without widening the embedded-library shape. Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Deliver operator policy controls for self-registration (allowlists, defaults, on/off, optional initial access tokens). Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Deliver RFC 7592 client configuration management with `registration_access_token` rotation and admin-UI provenance. Validated in Phase 26: protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
- Advertise `registration_endpoint` truthfully and bound SECURITY/support docs to the shipped DCR slice. Validated in v1.5 milestone.
- Close v1.5 with end-to-end verification, telemetry/audit coverage, and full traceability for shipped DCR requirements. Validated in v1.5 milestone.
"""

project = re.sub(
    r'- Deliver RFC 7591 `POST /register` intake bounded by operator policy without widening the embedded-library shape\. Validated in Phase 26.*?- Deliver RFC 7592 client configuration management.*?protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co\n',
    validated_addition,
    project,
    flags=re.DOTALL
)

# Update footer
project = re.sub(r'\*Last updated:.*?\*', '*Last updated: 2026-04-27 after v1.5 milestone*', project)

with open('.planning/PROJECT.md', 'w') as f:
    f.write(project)


with open('.planning/ROADMAP.md', 'r') as f:
    roadmap = f.read()

# Remove Active Milestone section from ROADMAP.md
roadmap = re.sub(
    r'## Active Milestone.*?(?=## Reference)',
    '',
    roadmap,
    flags=re.DOTALL
)

with open('.planning/ROADMAP.md', 'w') as f:
    f.write(roadmap)

