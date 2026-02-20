const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── In-Memory Store ──────────────────────────────────────────────────────────
// Trade-off: data resets on server restart. Acceptable for this assessment;
// in production you'd swap this array for a database (e.g. SQLite / Postgres).
let transactions = [];

// ─── Validation Helper ────────────────────────────────────────────────────────
// partial=true means we only validate fields that are present (used by PATCH)
function validateTransaction(body, partial = false) {
  const errors = [];
  const required = !partial;
  const { title, amount, type, category, date, note } = body;

  if (required || title !== undefined) {
    if (!title || typeof title !== 'string' || !title.trim()) {
      errors.push('title: required, must be a non-empty string');
    }
  }

  if (required || amount !== undefined) {
    if (amount == null) {
      errors.push('amount: required');
    } else if (typeof amount !== 'number' || isNaN(amount) || amount <= 0) {
      errors.push('amount: must be a positive number');
    }
  }

  if (required || type !== undefined) {
    if (!type) {
      errors.push('type: required');
    } else if (!['income', 'expense'].includes(type)) {
      errors.push('type: must be "income" or "expense"');
    }
  }

  if (required || category !== undefined) {
    if (!category || typeof category !== 'string' || !category.trim()) {
      errors.push('category: required, must be a non-empty string');
    }
  }

  if (required || date !== undefined) {
    if (!date) {
      errors.push('date: required');
    } else if (isNaN(Date.parse(date))) {
      errors.push('date: must be a valid ISO 8601 date string');
    }
  }

  if (note !== undefined && note !== null && typeof note !== 'string') {
    errors.push('note: must be a string or null');
  }

  return errors;
}

// ─── Routes ───────────────────────────────────────────────────────────────────

// GET /transactions — Return all transactions (newest date first)
app.get('/transactions', (req, res) => {
  const sorted = [...transactions].sort(
    (a, b) => new Date(b.date) - new Date(a.date)
  );
  res.json(sorted);
});

// POST /transactions — Create a new transaction
app.post('/transactions', (req, res) => {
  const errors = validateTransaction(req.body);
  if (errors.length) return res.status(400).json({ errors });

  const transaction = {
    id: uuidv4(),
    title: req.body.title.trim(),
    amount: Number(req.body.amount),
    type: req.body.type,
    category: req.body.category.trim(),
    date: req.body.date,
    note: req.body.note?.trim() || null,
    createdAt: new Date().toISOString(),
  };

  transactions.push(transaction);
  res.status(201).json(transaction);
});

// GET /transactions/:id — Get a single transaction
app.get('/transactions/:id', (req, res) => {
  const transaction = transactions.find((t) => t.id === req.params.id);
  if (!transaction) {
    return res.status(404).json({ error: `Transaction '${req.params.id}' not found` });
  }
  res.json(transaction);
});

// PATCH /transactions/:id — Update any field(s)
app.patch('/transactions/:id', (req, res) => {
  const idx = transactions.findIndex((t) => t.id === req.params.id);
  if (idx === -1) {
    return res.status(404).json({ error: `Transaction '${req.params.id}' not found` });
  }

  const errors = validateTransaction(req.body, true);
  if (errors.length) return res.status(400).json({ errors });

  // Destructure to protect immutable fields (id, createdAt) from being overwritten
  const { id: _id, createdAt: _createdAt, ...patch } = req.body;

  transactions[idx] = {
    ...transactions[idx],
    ...patch,
    id: transactions[idx].id,
    createdAt: transactions[idx].createdAt,
  };

  res.json(transactions[idx]);
});

// DELETE /transactions/:id — Delete a transaction
app.delete('/transactions/:id', (req, res) => {
  const idx = transactions.findIndex((t) => t.id === req.params.id);
  if (idx === -1) {
    return res.status(404).json({ error: `Transaction '${req.params.id}' not found` });
  }
  transactions.splice(idx, 1);
  res.status(204).end();
});

// GET /summary — Aggregate income, expenses, net balance
app.get('/summary', (req, res) => {
  const totalIncome = transactions
    .filter((t) => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  // Round to 2 decimal places to avoid floating-point noise
  res.json({
    totalIncome: Math.round(totalIncome * 100) / 100,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    netBalance: Math.round((totalIncome - totalExpenses) * 100) / 100,
  });
});

// ─── 404 catch-all ────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅  Finance Tracker API  →  http://localhost:${PORT}`);
  console.log(`    Endpoints:`);
  console.log(`      GET    /transactions`);
  console.log(`      POST   /transactions`);
  console.log(`      GET    /transactions/:id`);
  console.log(`      PATCH  /transactions/:id`);
  console.log(`      DELETE /transactions/:id`);
  console.log(`      GET    /summary`);
});
