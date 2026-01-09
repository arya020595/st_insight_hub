# VS Code Team Configuration

## 🎯 Purpose

This folder contains **team-wide VS Code settings** that are committed to git. All team members will automatically get these settings when they clone/pull the repository.

## 📦 Required Extensions

Install these extensions for the best development experience:

### Required

- **RuboCop** (`rubocop.vscode-rubocop`) - Auto-formats Ruby code on save
- **Ruby LSP** (`shopify.ruby-lsp`) - Language server for Ruby

### Installation

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. VS Code will prompt you to install recommended extensions
4. Click "Install All"

**OR** run this command:

```bash
code --install-extension rubocop.vscode-rubocop
code --install-extension shopify.ruby-lsp
```

## ✨ What's Configured

### Auto-Formatting

- ✅ **Format on Save**: All Ruby files auto-format when you save
- ✅ **RuboCop Auto-correct**: Automatically fixes style issues
- ✅ **Removes unused code**: Unused variables, methods, etc.
- ✅ **Trailing whitespace**: Automatically removed
- ✅ **Final newline**: Automatically added

### Keyboard Shortcuts

- `Ctrl+Shift+F` - Format current Ruby file
- `Ctrl+Alt+F` - Auto-correct all RuboCop issues

## 🚀 Quick Start for New Team Members

1. **Clone the repository**

   ```bash
   git clone <repo-url>
   cd st_intent_harvest
   ```

2. **Install dependencies**

   ```bash
   bundle install
   ```

3. **Open in VS Code**

   ```bash
   code .
   ```

4. **Install recommended extensions** (VS Code will prompt you)

5. **Done!** Ruby files will now auto-format on save 🎉

## 🔧 How to Test

1. Open any Ruby file (e.g., `app/controllers/payslips_controller.rb`)
2. Add some messy code:
   ```ruby
   def test
         x=1+2
       y    =    3
     return x+y
   end
   ```
3. Press `Ctrl+S` to save
4. Watch it auto-format! ✨

## 📝 Files in This Folder

- **`settings.json`** - VS Code workspace settings (auto-format, linting, etc.)
- **`extensions.json`** - Recommended extensions list
- **`keybindings.json`** - Custom keyboard shortcuts for Ruby
- **`README.md`** - This file!

## ⚙️ Configuration Files

The RuboCop rules are defined in:

- **`.rubocop.yml`** - Project-wide RuboCop configuration

## 🐛 Troubleshooting

### Auto-format not working?

1. **Check extension is installed**:

   - Open Extensions (Ctrl+Shift+X)
   - Search for "RuboCop"
   - Ensure `rubocop.vscode-rubocop` is installed

2. **Check RuboCop is in Gemfile**:

   ```bash
   bundle list | grep rubocop
   ```

3. **Reload VS Code window**:

   - Press `Ctrl+Shift+P`
   - Type "Reload Window"
   - Press Enter

4. **Check VS Code output**:
   - Press `Ctrl+Shift+U` (Output panel)
   - Select "RuboCop" from dropdown
   - Look for errors

### Still not working?

Run RuboCop manually to check if it works:

```bash
bundle exec rubocop -a app/controllers/
```

If this works but VS Code doesn't, try:

- Restart VS Code
- Check that Ruby extension is using the correct Ruby version
- Make sure you're in the workspace root folder

## 💡 Tips

1. **Commit often**: Auto-formatting happens on save, so you'll see clean diffs
2. **Review before committing**: Check what RuboCop changed
3. **Update .rubocop.yml**: Adjust rules as needed for your team's style
4. **Don't fight the formatter**: If RuboCop formats something differently, that's the team standard

## 📚 More Info

- [RuboCop Documentation](https://docs.rubocop.org/)
- [RuboCop VS Code Extension](https://marketplace.visualstudio.com/items?itemName=rubocop.vscode-rubocop)
- [Ruby Style Guide](https://rubystyle.guide/)

---

**Questions?** Ask the team or check `docs/RUBOCOP_AUTO_FORMAT_GUIDE.md`
