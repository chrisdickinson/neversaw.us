export PATH := env_var("PATH") + ":" + justfile_directory() + "/bin"
set positional-arguments

@_help:
	just --list


# Setup dependencies. Run automatically by other recipes.
_setup:
	#!/bin/bash
	set -eou pipefail
	mkdir -p bin
	arch=$(uname -m | sed -e 's/arm64/aarch64/g')
	plat=$(uname | tr '[:upper:]' '[:lower:]')
	if ! &>/dev/null which zola; then
		url=($(curl -s https://api.github.com/repos/getzola/zola/releases/latest | jq -r '.assets[].browser_download_url' | grep $plat | grep $arch))
		echo -e '\x1b[33mDownloading zola from \x1b[33;4m'${url[0]}'\x1b[0m...'
		curl -sL ${url[0]} | tar xz -C ./bin
		chmod +x bin/zola
		bin/zola --version
	fi
	if ! &>/dev/null which likelike; then
		gh release download --repo chrisdickinson/likelike -p '*'"$plat"'*'
		<likelike*.tar.gz tar zxv -C ./bin
		rm likelike*.tar.gz
		mkdir -p ~/.local/share/likelike
	fi
	if [ ! -d node_modules/playwright ]; then
		npm ci
		npx playwright install chromium
	fi

# Check that the site build works without outputting any files. (All options are forwarded to "zola check")
@check: _setup
	bin/zola

# Build the site.
@build *args: _setup
	zola build $@

# Serve the website. (All options are forwarded to "zola serve", including "--help".)
@serve:
	zola serve $@

export NODE_PATH := justfile_directory() + "/node_modules"

# Generate OpenGraph preview images for blog OG_POSTS
[script("node")]
og *posts:
	const fs = require('fs');
	const path = require('path');
	const YAML = require('js-yaml');
	const { chromium } = require('playwright');
	const { parse: parseToml } = require('smol-toml');

	const ROOT = '{{ justfile_directory() }}';
	const TEMPLATE = fs.readFileSync(path.join(ROOT, 'templates', 'og-image.html'), 'utf8');
	const FONTS_DIR = 'https://www.neversaw.us/fonts/';
	const AVATAR_SRC = 'https://www.neversaw.us/img/profile-2026.jpeg';

	function escapeHtml(s) {
		return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}

	function parseFrontmatter(content) {
		if (content.startsWith('+++')) {
			const end = content.indexOf('+++', 3);
			return parseToml(content.slice(3, end));
		}
		if (content.startsWith('---')) {
			const end = content.indexOf('---', 3);
			return YAML.load(content.slice(3, end));
		}
		throw new Error('No frontmatter found');
	}

	function slugToPath(slug) {
		const p = slug.startsWith('/') ? slug : '/' + slug;
		return p.endsWith('/') ? p : p + '/';
	}

	const posts = process.argv.slice(2)
	if (!posts.length) {
		console.error('Usage: just og <post.md> [post.md ...]');
		process.exit(1);
	}

	async function main() {
		const browser = await chromium.launch();
		try {
			for (const file of posts) {
				const content = fs.readFileSync(path.resolve(ROOT, file), 'utf8');
				const fm = parseFrontmatter(content);
				const title = fm.title || path.basename(file, '.md');
				const description = fm.description || '';
				const slug = fm.slug;
				if (!slug) {
					continue;
				}

				const pagePath = slugToPath(slug);
				const outDir = path.join(ROOT, 'static', 'previews', ...pagePath.split('/').filter(Boolean));
				fs.mkdirSync(outDir, { recursive: true });

				const html = TEMPLATE
					.replace(/FONTS_DIR/g, FONTS_DIR)
					.replace('AVATAR_SRC', AVATAR_SRC)
					.replace('OG_TITLE', escapeHtml(title))
					.replace('OG_DESCRIPTION', escapeHtml(description));

				const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
				await page.setContent(html, { waitUntil: 'networkidle' });
				await page.screenshot({ path: path.join(outDir, 'preview.png'), type: 'png' });
				await page.close();

				console.log(`static/previews${pagePath}preview.png`);
			}
		} finally {
			await browser.close();
		}
	}
	main().catch(err => { console.error(err); process.exit(1) })
