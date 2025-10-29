#!/usr/bin/env node
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
(async () => {
    const prisma = new PrismaClient();
    try {
        const email = process.env.TEST_EMAIL || 'test@example.com';
        const password = process.env.TEST_PASSWORD || 'password123';
        const hash = await bcrypt.hash(password, 12);
        const existing = await prisma.user.findUnique({ where: { email } });
        if (existing) {
            console.log(`User already exists: ${email}`);
            process.exit(0);
        }
        const user = await prisma.user.create({ data: { email, password: hash, name: 'Test User' } });
        console.log('Created user:');
        console.log(`  email: ${email}`);
        console.log(`  password: ${password}`);
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
})();
