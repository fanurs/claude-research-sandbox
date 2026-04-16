const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const LOGS_DIR = path.join(__dirname, '../../logs');

app.use(express.static(path.join(__dirname, 'public')));

// List session JSON files, sorted newest first
app.get('/api/files', (req, res) => {
  try {
    const files = fs.readdirSync(LOGS_DIR)
      .filter(f => /^session_[\d_-]+\.json$/.test(f))
      .map(name => {
        const stat = fs.statSync(path.join(LOGS_DIR, name));
        return { name, size: stat.size, mtime: stat.mtimeMs };
      })
      .sort((a, b) => b.mtime - a.mtime);
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Read lines from a log file, starting at offset
app.get('/api/lines/:filename', (req, res) => {
  const { filename } = req.params;
  const offset = parseInt(req.query.offset) || 0;

  // Validate filename to prevent path traversal
  if (!/^session_[\d_-]+\.json$/.test(filename)) {
    return res.status(400).json({ error: 'Invalid filename' });
  }

  const filePath = path.join(LOGS_DIR, filename);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const allLines = content.split('\n').filter(l => l.trim());
    const newLines = allLines.slice(offset);

    const parsed = [];
    for (const line of newLines) {
      try {
        parsed.push(JSON.parse(line));
      } catch {
        // Skip partially written lines (active session)
      }
    }

    res.json({ lines: parsed, total: allLines.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Log viewer running at http://localhost:${PORT}`);
});
