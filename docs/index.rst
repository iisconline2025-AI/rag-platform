IISc Grounded Agentic RAG Platform
====================================

.. image:: https://img.shields.io/badge/backend-live-success?logo=railway
   :target: https://rag-platform-production.up.railway.app/docs
.. image:: https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi
   :target: https://fastapi.tiangolo.com
.. image:: https://img.shields.io/badge/python-3.11+-3776AB?logo=python&logoColor=white
   :target: https://python.org

**Multi-tenant SaaS platform for grounded, citation-backed Q&A across Web, WhatsApp, and Slack.**

Upload your documents. Ask questions. Get answers grounded in your sources — never hallucinated.

.. note::

   This documentation is auto-built from the ``docs/`` directory and deployed
   to GitHub Pages via GitHub Actions on every push to ``dev``.

Quick Links
-----------

- **Live API**: https://rag-platform-production.up.railway.app/docs
- **GitHub Repository**: https://github.com/iisconline2025-AI/rag-platform
- **n8n Workflows**: https://n8n-production-c637.up.railway.app/

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   getting-started/overview
   getting-started/quickstart
   getting-started/deployment

.. toctree::
   :maxdepth: 2
   :caption: Architecture

   architecture/system-design
   architecture/data-flows
   architecture/security

.. toctree::
   :maxdepth: 2
   :caption: Backend API

   backend/auth
   backend/admin
   backend/chat
   backend/webhooks
   backend/mcp

.. toctree::
   :maxdepth: 2
   :caption: RAG Engine (n8n)

   n8n/ingestion
   n8n/retrieval

.. toctree::
   :maxdepth: 2
   :caption: Evaluation

   evaluation/framework
   evaluation/metrics

.. toctree::
   :maxdepth: 2
   :caption: Development

   development/contributing
   development/team
   development/api-reference

.. toctree::
   :maxdepth: 1
   :caption: Guides

   DEMO
   LOCAL_SETUP

.. toctree::
   :hidden:

   diagrams/README


Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
