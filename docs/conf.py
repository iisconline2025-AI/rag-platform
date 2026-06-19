"""Sphinx configuration for IISc Grounded Agentic RAG Platform documentation."""

import os
import sys

# -- Path setup ---------------------------------------------------------------
# Add backend to sys.path so autodoc can import modules
sys.path.insert(0, os.path.abspath(os.path.join("..", "backend")))

# -- Project information ------------------------------------------------------
project = "IISc RAG Platform"
copyright = "2026, IISc Bengaluru — DA225o Deep Learning"
author = "IISc RAG Platform Team (13 Members)"
release = "1.0.0"

# -- General configuration ----------------------------------------------------
extensions = [
    "myst_parser",                  # Markdown support (reads .md files)
    "sphinxcontrib.mermaid",        # Mermaid diagrams
    "sphinx_copybutton",            # Copy button on code blocks
    "sphinx.ext.autodoc",           # Auto-generate from docstrings
    "sphinx.ext.viewcode",          # Link to source code
    "sphinx.ext.napoleon",          # Google/NumPy docstring style
    "sphinx.ext.intersphinx",       # Cross-reference external docs
    "sphinx.ext.todo",              # TODO directive support
]

# MyST (Markdown) parser settings
myst_enable_extensions = [
    "colon_fence",       # ::: directive syntax
    "deflist",           # definition lists
    "fieldlist",         # field lists
    "tasklist",          # - [x] checkboxes
]
myst_heading_anchors = 3

# Source file suffixes
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

# Files to ignore
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# Mock heavy backend dependencies so autodoc / autosummary can import
# the Python modules during CI builds without installing everything.
autodoc_mock_imports = [
    "fastapi", "pydantic", "pydantic_settings", "sqlalchemy",
    "asyncpg", "alembic", "passlib", "jose", "slowapi",
    "httpx", "uvicorn", "twilio", "slack_sdk",
    "openai", "voyageai",
]

# -- HTML output --------------------------------------------------------------
html_theme = "furo"
html_theme_options = {
    "navigation_with_keys": True,
}

html_title = "IISc RAG Platform Documentation"
html_short_title = "RAG Platform"
html_show_sourcelink = True
html_static_path = ["_static"]

# -- Intersphinx mapping ------------------------------------------------------
intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
    "fastapi": ("https://fastapi.tiangolo.com", None),
    "sqlalchemy": ("https://docs.sqlalchemy.org/en/20/", None),
}

# -- Autodoc settings ---------------------------------------------------------
autodoc_default_options = {
    "members": True,
    "undoc-members": True,
    "show-inheritance": True,
}
autodoc_mock_imports = [
    "slowapi",
    "passlib",
    "jose",
    "twilio",
    "slack_sdk",
    "mcp",
    "pgvector",
]

# -- Todo extension -----------------------------------------------------------
todo_include_todos = True
