# Orchestration Examples

## Example 1: Full-Stack Feature

**User request:** "Add user profile page with avatar upload"

### Task Decomposition

```json
[
  {
    "id": 1,
    "subject": "Profile API endpoint",
    "description": "Create a REST API endpoint at /api/users/profile.\n\nProject: /home/user/myapp (Next.js 15, TypeScript, Prisma + PostgreSQL)\n\nRequired endpoints:\n- GET /api/users/profile — return current user profile\n- PATCH /api/users/profile — update displayName, bio fields\n- POST /api/users/profile/avatar — accept multipart file upload, store in /public/avatars/, update user.avatarUrl\n\nConstraints:\n- Use existing auth middleware at src/lib/auth.ts\n- Follow existing API patterns in src/app/api/\n- Max avatar size: 2MB, formats: jpg/png/webp\n- Return standard { success, data, error } response shape",
    "worker_type": "codex",
    "model": "gpt-5.3-codex"
  },
  {
    "id": 2,
    "subject": "Profile UI component",
    "description": "Create a user profile page at /profile.\n\nProject: /home/user/myapp (Next.js 15, TypeScript, Tailwind CSS, shadcn/ui)\n\nRequired:\n- Profile page at src/app/profile/page.tsx\n- Display user avatar (circular, 96px), displayName, bio\n- Edit mode: inline editing for displayName and bio\n- Avatar upload: click avatar to trigger file picker, preview before upload\n- Loading and error states\n\nConstraints:\n- Use shadcn/ui components (Button, Input, Textarea, Avatar)\n- Follow existing page layout in src/app/dashboard/page.tsx\n- API endpoints: GET/PATCH /api/users/profile, POST /api/users/profile/avatar\n- Mobile responsive (sm/md/lg breakpoints)",
    "worker_type": "gemini",
    "model": "gemini-3.1-pro"
  }
]
```

---

## Example 2: Code Review

**User request:** "Review the auth module for security issues"

```json
[
  {
    "id": 1,
    "subject": "Auth backend security review",
    "description": "Security review of authentication backend code.\n\nFiles to review:\n- /home/user/myapp/src/lib/auth.ts\n- /home/user/myapp/src/app/api/auth/[...nextauth]/route.ts\n- /home/user/myapp/src/middleware.ts\n\nCheck for:\n- JWT validation issues (algorithm confusion, expiry)\n- Session fixation or hijacking vectors\n- CSRF protection gaps\n- SQL injection in user queries\n- Timing attacks on password comparison\n- Proper bcrypt/argon2 usage\n- Secure cookie flags (httpOnly, secure, sameSite)\n\nOutput: List each finding with severity (critical/high/medium/low), affected file:line, description, and suggested fix.",
    "worker_type": "codex",
    "model": "gpt-5.3-codex"
  },
  {
    "id": 2,
    "subject": "Auth frontend security review",
    "description": "Security review of authentication frontend code.\n\nFiles to review:\n- /home/user/myapp/src/app/login/page.tsx\n- /home/user/myapp/src/app/register/page.tsx\n- /home/user/myapp/src/components/AuthProvider.tsx\n- /home/user/myapp/src/hooks/useAuth.ts\n\nCheck for:\n- XSS vectors in form inputs\n- Token storage (localStorage vs httpOnly cookie)\n- Sensitive data in client-side state\n- Form validation bypass\n- OAuth redirect URI validation\n- Error messages leaking user existence\n\nOutput: List each finding with severity, affected file:line, description, and suggested fix.",
    "worker_type": "gemini",
    "model": "gemini-3.1-pro"
  }
]
```

---

## Example 3: Research & Analysis

**User request:** "Analyze our DB queries for performance bottlenecks"

```json
[
  {
    "id": 1,
    "subject": "Analyze slow Prisma queries",
    "description": "Analyze Prisma queries for performance issues.\n\nProject: /home/user/myapp\nORM: Prisma with PostgreSQL\nSchema: /home/user/myapp/prisma/schema.prisma\n\nScan all files matching src/**/*.ts for Prisma client usage.\n\nCheck for:\n- N+1 query patterns (missing include/select)\n- Missing database indexes for filtered/sorted fields\n- Large unbounded queries (no take/skip)\n- Unnecessary field selection (select * equivalent)\n- Transaction misuse\n\nFor each finding, provide:\n- File and line\n- Current query code\n- Problem explanation\n- Suggested fix with code\n- Expected performance impact",
    "worker_type": "codex",
    "model": "gpt-5.3-codex"
  }
]
```
