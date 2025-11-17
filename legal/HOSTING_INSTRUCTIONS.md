# How to Host Privacy Policy & Terms of Service

Google Play Store **requires** that your Privacy Policy is hosted at a **publicly accessible URL**. Here are your options:

---

## Option 1: GitHub Pages (FREE & Recommended)

**Pros:** Free, version control, easy updates, professional
**Cons:** Requires GitHub account

### Steps:

1. **Create a GitHub Repository**
   ```bash
   # Create a new public repository called "gratistellar-legal"
   ```

2. **Add Legal Documents**
   - Upload `PRIVACY_POLICY.md`
   - Upload `TERMS_OF_SERVICE.md`
   - Upload `DATA_DELETION.md`

3. **Enable GitHub Pages**
   - Go to repository Settings → Pages
   - Source: Deploy from main branch
   - Select `/` (root)
   - Save

4. **Your URLs will be:**
   ```
   https://[YOUR-USERNAME].github.io/gratistellar-legal/PRIVACY_POLICY
   https://[YOUR-USERNAME].github.io/gratistellar-legal/TERMS_OF_SERVICE
   https://[YOUR-USERNAME].github.io/gratistellar-legal/DATA_DELETION
   ```

5. **Optional: Custom Domain**
   - Buy domain (e.g., gratistellar.app)
   - Add CNAME record
   - Configure in GitHub Pages settings

---

## Option 2: Firebase Hosting (FREE, Same Infrastructure)

**Pros:** Uses same Firebase project, integrated, fast CDN
**Cons:** Requires Firebase CLI setup

### Steps:

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Create `public` folder**
   ```bash
   mkdir public
   # Convert .md files to .html or use as-is
   cp legal/PRIVACY_POLICY.md public/privacy.html
   cp legal/TERMS_OF_SERVICE.md public/terms.html
   cp legal/DATA_DELETION.md public/data-deletion.html
   ```

3. **Initialize Firebase Hosting**
   ```bash
   firebase init hosting
   # Select your project
   # Public directory: public
   # Configure as single-page app: No
   # Don't overwrite files
   ```

4. **Deploy**
   ```bash
   firebase deploy --only hosting
   ```

5. **Your URLs will be:**
   ```
   https://gratistellar.web.app/privacy.html
   https://gratistellar.web.app/terms.html
   https://gratistellar.web.app/data-deletion.html
   ```

---

## Option 3: Simple HTML on Any Web Host

**Pros:** Full control, any hosting provider
**Cons:** Requires web hosting account

### Steps:

1. **Convert Markdown to HTML**
   - Use online converter or Pandoc
   - Or manually create HTML files

2. **Upload to Web Host**
   - Use FTP/SFTP or hosting control panel
   - Upload to `public_html/legal/`

3. **Your URLs will be:**
   ```
   https://yourwebsite.com/legal/privacy.html
   https://yourwebsite.com/legal/terms.html
   https://yourwebsite.com/legal/data-deletion.html
   ```

---

## Option 4: Google Sites (FREE, No Technical Skills)

**Pros:** Very easy, no coding required
**Cons:** Less professional looking

### Steps:

1. Go to https://sites.google.com
2. Create a new site
3. Add pages for Privacy Policy, Terms, Data Deletion
4. Copy/paste content from .md files
5. Publish
6. Your URL: `https://sites.google.com/view/gratistellar-legal`

---

## Option 5: Notion (FREE & Easy)

**Pros:** Beautiful formatting, easy to update
**Cons:** Notion branding on free plan

### Steps:

1. Create Notion account
2. Create new pages for each document
3. Make pages public (Share → Anyone with link can view)
4. Copy public URLs
5. URLs look like: `https://notion.so/Privacy-Policy-xxx`

---

## What to Do After Hosting

### 1. Fill in Placeholders

In all three documents, replace:
- `[INSERT DATE]` - Current date (YYYY-MM-DD format)
- `[INSERT SUPPORT EMAIL]` - Your support email (e.g., support@gratistellar.app)
- `[INSERT MAILING ADDRESS]` - Physical address (PO Box is fine)
- `[INSERT JURISDICTION]` - Your legal jurisdiction (e.g., "California, USA")
- `[INSERT PRIVACY POLICY URL]` - The URL where privacy policy is hosted

### 2. Update Google Play Listing

When submitting your app:
1. Go to Google Play Console
2. Navigate to: App Content → Privacy Policy
3. Enter your Privacy Policy URL
4. Save

### 3. Add Links in App (Optional but Recommended)

Add to app drawer or settings:
```dart
ListTile(
  leading: Icon(Icons.privacy_tip),
  title: Text('Privacy Policy'),
  onTap: () => launch('https://your-url/privacy.html'),
),
ListTile(
  leading: Icon(Icons.description),
  title: Text('Terms of Service'),
  onTap: () => launch('https://your-url/terms.html'),
),
```

### 4. Keep Documents Updated

- Review annually
- Update "Last Updated" date when changes are made
- Notify users of material changes via in-app notification

---

## Quick Hosting Decision Tree

```
Do you have a website already?
├─ YES → Use your existing hosting (Option 3)
└─ NO
    │
    Do you know Git/GitHub?
    ├─ YES → Use GitHub Pages (Option 1) ⭐ RECOMMENDED
    └─ NO
        │
        Already using Firebase?
        ├─ YES → Use Firebase Hosting (Option 2)
        └─ NO → Use Google Sites (Option 4) for quickest setup
```

---

## Sample HTML Template

If you need a simple HTML version:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GratiStellar - Privacy Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
        }
        h1 { color: #1a237e; border-bottom: 3px solid #1a237e; padding-bottom: 10px; }
        h2 { color: #283593; margin-top: 30px; }
        h3 { color: #3949ab; }
        a { color: #1976d2; }
        .last-updated { color: #666; font-style: italic; }
    </style>
</head>
<body>
    <!-- Paste your markdown content here (converted to HTML) -->
    
    <h1>Privacy Policy for GratiStellar</h1>
    <p class="last-updated">Last Updated: [DATE]</p>
    
    <!-- Rest of content -->
    
</body>
</html>
```

---

## Legal Compliance Checklist

- [ ] Privacy Policy hosted at public URL
- [ ] Terms of Service accessible
- [ ] Data Deletion instructions provided
- [ ] URLs added to Google Play listing
- [ ] All placeholder text filled in
- [ ] Effective date set
- [ ] Support email active
- [ ] Tested URLs on mobile devices
- [ ] SSL/HTTPS enabled (for credibility)
- [ ] Links added in app settings (optional)

---

## Need Help?

- **Markdown to HTML:** https://markdowntohtml.com/
- **GitHub Pages Guide:** https://pages.github.com/
- **Firebase Hosting Docs:** https://firebase.google.com/docs/hosting
- **Google Sites:** https://sites.google.com/

---

**Recommendation:** Use **GitHub Pages** (Option 1). It's free, professional, version-controlled, and you can update documents by just editing markdown files. Perfect for an app in active development.

