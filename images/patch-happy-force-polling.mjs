#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const repoRoot = process.argv[2];

if (!repoRoot) {
  console.error("Usage: node patch-happy-force-polling.mjs <happy-repo-root>");
  process.exit(1);
}

const replacements = [
  {
    file: "packages/happy-cli/src/api/apiMachine.ts",
    before: `import { io, Socket } from 'socket.io-client';`,
    after: `import { io, Socket } from 'socket.io-client';
import { HttpsProxyAgent } from 'https-proxy-agent';`,
  },
  {
    file: "packages/happy-cli/src/api/apiMachine.ts",
    before: `export class ApiMachineClient {`,
    after: `function createSocketProxyAgent() {
    const proxyUrl = process.env.HTTPS_PROXY || process.env.https_proxy || process.env.HTTP_PROXY || process.env.http_proxy;
    if (!proxyUrl) {
        return undefined;
    }

    try {
        return new HttpsProxyAgent(proxyUrl);
    } catch (error) {
        logger.debug('[API MACHINE] Failed to create proxy agent:', error);
        return undefined;
    }
}

export class ApiMachineClient {`,
  },
  {
    file: "packages/happy-cli/src/api/apiMachine.ts",
    before: `        this.socket = io(serverUrl, {
            transports: ['websocket'],
            auth: {`,
    after: `        const proxyAgent = createSocketProxyAgent();

        this.socket = io(serverUrl, {
            transports: ['websocket'],
            agent: proxyAgent as any,
            auth: {`,
  },
  {
    file: "packages/happy-cli/src/api/apiSession.ts",
    before: `import { io, Socket } from 'socket.io-client'`,
    after: `import { io, Socket } from 'socket.io-client'
import { HttpsProxyAgent } from 'https-proxy-agent'`,
  },
  {
    file: "packages/happy-cli/src/api/apiSession.ts",
    before: `export class ApiSessionClient extends EventEmitter {`,
    after: `function createSocketProxyAgent() {
    const proxyUrl = process.env.HTTPS_PROXY || process.env.https_proxy || process.env.HTTP_PROXY || process.env.http_proxy;
    if (!proxyUrl) {
        return undefined;
    }

    try {
        return new HttpsProxyAgent(proxyUrl);
    } catch (error) {
        logger.debug('[API] Failed to create proxy agent:', error);
        return undefined;
    }
}

export class ApiSessionClient extends EventEmitter {`,
  },
  {
    file: "packages/happy-cli/src/api/apiSession.ts",
    before: `        this.socket = io(configuration.serverUrl, {
            auth: {
                token: this.token,
                clientType: 'session-scoped' as const,
                sessionId: this.sessionId,
                happyClient: \`cli-coding-session/\${configuration.currentCliVersion}\`
            },
            path: '/v1/updates',
            reconnection: false,
            transports: ['websocket'],
            withCredentials: true,
            autoConnect: false
        });`,
    after: `        const proxyAgent = createSocketProxyAgent();

        this.socket = io(configuration.serverUrl, {
            auth: {
                token: this.token,
                clientType: 'session-scoped' as const,
                sessionId: this.sessionId,
                happyClient: \`cli-coding-session/\${configuration.currentCliVersion}\`
            },
            path: '/v1/updates',
            reconnection: false,
            transports: ['websocket'],
            agent: proxyAgent as any,
            withCredentials: true,
            autoConnect: false
        });`,
  },
  {
    file: "packages/happy-cli/src/codex/executionPolicy.ts",
    before: `export function resolveCodexExecutionPolicy(
    permissionMode: import('@/api/types').PermissionMode,
    sandboxManagedByHappy: boolean,
): { approvalPolicy: ApprovalPolicy; sandbox: SandboxMode } {
    if (sandboxManagedByHappy) {
        return {
            approvalPolicy: 'never',
            sandbox: 'danger-full-access',
        };
    }`,
    after: `export function resolveCodexExecutionPolicy(
    permissionMode: import('@/api/types').PermissionMode,
    sandboxManagedByHappy: boolean,
): { approvalPolicy: ApprovalPolicy; sandbox: SandboxMode } {
    const forceDangerousCodexMode = process.env.HAPPY_CODEX_FORCE_FULL_ACCESS === '1'
        || process.env.HAPPY_CODEX_FORCE_FULL_ACCESS === 'true';

    if (sandboxManagedByHappy || forceDangerousCodexMode) {
        return {
            approvalPolicy: 'never',
            sandbox: 'danger-full-access',
        };
    }`,
  },
];

for (const replacement of replacements) {
  const filePath = path.join(repoRoot, replacement.file);
  const original = fs.readFileSync(filePath, "utf8");

  if (!original.includes(replacement.before)) {
    console.error(`Expected patch context not found in ${replacement.file}`);
    process.exit(1);
  }

  const patched = original.replace(replacement.before, replacement.after);
  fs.writeFileSync(filePath, patched);
  console.log(`Patched ${replacement.file}`);
}

const happyCliPackageJsonPath = path.join(repoRoot, "packages/happy-cli/package.json");
const happyCliPackageJson = JSON.parse(fs.readFileSync(happyCliPackageJsonPath, "utf8"));

happyCliPackageJson.dependencies ||= {};
if (!happyCliPackageJson.dependencies["https-proxy-agent"]) {
  happyCliPackageJson.dependencies["https-proxy-agent"] = "^7.0.6";
  fs.writeFileSync(happyCliPackageJsonPath, `${JSON.stringify(happyCliPackageJson, null, 2)}\n`);
  console.log("Patched packages/happy-cli/package.json");
}
