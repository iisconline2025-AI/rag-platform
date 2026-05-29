"""Pytest configuration and shared fixtures. Owner: M10."""
import pytest
import pytest_asyncio

@pytest.fixture
def mock_tenant_id():
    return "11111111-1111-1111-1111-111111111111"

@pytest.fixture
def mock_user_id():
    return "22222222-2222-2222-2222-222222222222"
