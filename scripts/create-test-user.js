#!/usr/bin/env node
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const readline = require('node:readline/promises');
const { stdin, stdout } = require('node:process');
const { spawn } = require('node:child_process');

async function promptNext(exitCode) {
    if (exitCode !== 0) {
        return;
    }
    if (!stdin.isTTY || !stdout.isTTY) {
        return;
    }

    const rl = readline.createInterface({ input: stdin, output: stdout });
    try {
        const answer = await rl.question('Start the dev server with "pnpm dev"? [y/N] ');
        if (/^[Yy](es)?$/.test(answer.trim())) {
            console.log('Starting pnpm dev ...');
            await new Promise((resolve) => {
                const child = spawn('pnpm', ['dev'], { stdio: 'inherit' });
                child.on('error', (err) => {
                    console.error(`Failed to launch pnpm dev: ${err.message}`);
                    resolve();
                });
                child.on('exit', (code, signal) => {
                    if (signal) {
                        console.warn(`pnpm dev exited via signal ${signal}.`);
                    } else if (typeof code === 'number' && code !== 0) {
                        console.warn(`pnpm dev exited with code ${code}.`);
                    }
                    resolve();
                });
            });
        } else {
            console.log('Skipping pnpm dev.');
        }
    } finally {
        rl.close();
    }
}

(async () => {
    const prisma = new PrismaClient();
    let exitCode = 0;
    try {
        const email = process.env.TEST_EMAIL || 'test@example.com';
        const password = process.env.TEST_PASSWORD || 'password123';
        const hash = await bcrypt.hash(password, 12);
        const existing = await prisma.user.findUnique({ where: { email } });
        if (existing) {
            console.log(`User already exists: ${email}`);
        } else {
            const isAdmin = process.env.TEST_ADMIN === 'true';
            await prisma.user.create({
                data: {
                    email,
                    password: hash,
                    name: 'Test User',
                    role: isAdmin ? 'admin' : 'user',
                },
            });
            console.log('Created user:');
            console.log(`  email: ${email}`);
            console.log(`  password: ${password}`);
            console.log(`  role: ${isAdmin ? 'admin' : 'user'}`);
        }
    } catch (e) {
        console.error(e);
        exitCode = 1;
    } finally {
        await prisma.$disconnect();
    }

    await promptNext(exitCode);
    process.exit(exitCode);
})();
