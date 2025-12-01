const { test, expect } = require('@playwright/test');

// Testa fluxo básico: login, listar usuários, criar e deletar usuário
// Requer backend em http://localhost:8081 e frontend em http://localhost:5173 (vite dev)

const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost:5173';
const API_USER = process.env.E2E_API_USER || 'admin';
const API_PASS = process.env.E2E_API_PASS || '123456';

function randomSuffix() {
  return Math.random().toString(36).substring(2, 8);
}

test.describe('UI flows', () => {
  test('login, list, create and delete user', async ({ page }) => {
    await page.goto(BASE_URL);

    // Login
    await page.fill('#username', API_USER);
    await page.fill('#password', API_PASS);
    await page.click('button:has-text("Entrar")');

    // Wait for dashboard to load (button Novo Usuário appears)
    await page.waitForSelector('button:has-text("Novo Usuário")', { timeout: 5000 });

    // Ensure users table is present
    await expect(page.locator('text=Usuários').first()).toBeVisible();

    // Create a unique user
    const suffix = randomSuffix();
    const testName = `e2e-${suffix}`;
    await page.click('button:has-text("Novo Usuário")');

    // Fill form (fields: Nome, E-mail, Senha)
    await page.fill('input[placeholder="Nome"]', testName);
    await page.fill('input[placeholder="E-mail"]', `${testName}@example.local`);
    await page.fill('input[placeholder="Senha"]', 'Test1234!');
    await page.click('button:has-text("Salvar")');

    // Wait for table to refresh and contain new user
    const row = page.locator('table tbody tr').filter({ hasText: testName }).first();
    await expect(row).toBeVisible({ timeout: 5000 });

    // Delete the new user by clicking the Deletar button in the same row
    const deleteBtn = row.locator('button:has-text("Deletar")').first();

    // Handle confirm dialog
    page.on('dialog', async dialog => { await dialog.accept(); });

    await deleteBtn.click();

    // Expect the row to be removed
    await expect(page.locator('table tbody tr').filter({ hasText: testName })).toHaveCount(0, { timeout: 5000 });
  });
});
