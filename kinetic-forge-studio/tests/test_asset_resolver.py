
import unittest
from unittest.mock import patch, MagicMock, mock_open
import os
import shutil

# Assuming these are available from previously completed tasks
from backend.kfs_manifest.asset_types import FileAsset, GitAsset, HttpAsset
from backend.kfs_manifest.asset_resolver import AssetResolver
from backend.kfs_manifest.errors import AssetResolutionError

class TestAssetResolver(unittest.TestCase):

    def setUp(self):
        # Create a temporary cache directory and base path for tests
        self.test_cache_dir = os.path.abspath("./test_kfs_cache_resolver")
        self.test_base_path = os.path.abspath("./test_base_path_resolver")
        os.makedirs(self.test_cache_dir, exist_ok=True)
        os.makedirs(self.test_base_path, exist_ok=True)

        self.resolver = AssetResolver(cache_dir=self.test_cache_dir, base_path=self.test_base_path)

    def tearDown(self):
        # Clean up the temporary directories
        if os.path.exists(self.test_cache_dir):
            shutil.rmtree(self.test_cache_dir)
        if os.path.exists(self.test_base_path):
            shutil.rmtree(self.test_base_path)

    @patch("os.path.exists", return_value=True) # Assume files exist for file asset checks
    def test_resolve_file_asset_relative(self, mock_exists):
        file_asset = FileAsset(path="model.glb")
        expected_path = os.path.abspath(os.path.join(self.test_base_path, "model.glb"))
        resolved_path = self.resolver.resolve(file_asset)
        self.assertEqual(resolved_path, expected_path)

    def test_resolve_file_asset_absolute_outside_base_raises(self):
        """Absolute paths outside base_path should be rejected (path traversal prevention)."""
        absolute_path = "/path/to/absolute/model.glb"
        file_asset = FileAsset(path=absolute_path)
        with self.assertRaises(AssetResolutionError) as cm:
            self.resolver.resolve(file_asset)
        self.assertIn("Path traversal detected", str(cm.exception))

    def test_resolve_file_asset_traversal_raises(self):
        """Paths with ../../ that escape base_path should be rejected."""
        file_asset = FileAsset(path="../../etc/passwd")
        with self.assertRaises(AssetResolutionError) as cm:
            self.resolver.resolve(file_asset)
        self.assertIn("Path traversal detected", str(cm.exception))

    @patch("backend.kfs_manifest.asset_resolver.AssetResolver._resolve_git_asset", return_value="/mock/resolved/git/repo")
    def test_resolve_git_asset(self, mock_git_resolver):
        git_asset = GitAsset(url="https://github.com/user/repo.git", reference="main")
        resolved_path = self.resolver.resolve(git_asset)
        self.assertEqual(resolved_path, "/mock/resolved/git/repo")
        mock_git_resolver.assert_called_once_with(git_asset)

    @patch("backend.kfs_manifest.asset_resolver.AssetResolver._resolve_http_asset", return_value="/mock/resolved/http/asset.glb")
    def test_resolve_http_asset(self, mock_http_resolver):
        http_asset = HttpAsset(url="https://example.com/asset.glb")
        resolved_path = self.resolver.resolve(http_asset)
        self.assertEqual(resolved_path, "/mock/resolved/http/asset.glb")
        mock_http_resolver.assert_called_once_with(http_asset)

    def test_resolve_unsupported_asset_type(self):
        class UnknownAsset:
            pass
        unknown_asset = UnknownAsset()
        with self.assertRaises(TypeError) as cm:
            self.resolver.resolve(unknown_asset)
        self.assertIn("Unsupported asset type", str(cm.exception))

    @patch("os.makedirs")
    @patch("builtins.open", new_callable=mock_open)
    @patch("os.path.exists")
    def test_git_asset_caching_first_call(self, mock_exists, mock_file_open, mock_makedirs):
        git_asset = GitAsset(url="https://github.com/test/repo.git", reference="main")
        repo_name = os.path.basename(git_asset.url).replace(".git", "")
        expected_cached_path = os.path.join(self.test_cache_dir, f"{repo_name}-{git_asset.reference.replace('/', '_')}")

        mock_exists.side_effect = lambda path: path == expected_cached_path and False # Not exists initially

        resolved_path = self.resolver._resolve_git_asset(git_asset)
        self.assertEqual(resolved_path, expected_cached_path)
        mock_exists.assert_any_call(expected_cached_path) # Check if it checked for existence
        mock_makedirs.assert_called_with(expected_cached_path, exist_ok=True) # Should attempt to create
        mock_file_open.assert_called() # Should simulate writing content

    @patch("os.makedirs")
    @patch("builtins.open", new_callable=mock_open)
    @patch("os.path.exists")
    def test_git_asset_caching_second_call(self, mock_exists, mock_file_open, mock_makedirs):
        git_asset = GitAsset(url="https://github.com/test/repo.git", reference="main")
        repo_name = os.path.basename(git_asset.url).replace(".git", "")
        expected_cached_path = os.path.join(self.test_cache_dir, f"{repo_name}-{git_asset.reference.replace('/', '_')}")

        mock_exists.side_effect = lambda path: path == expected_cached_path and True # Already exists

        resolved_path = self.resolver._resolve_git_asset(git_asset)
        self.assertEqual(resolved_path, expected_cached_path)
        mock_exists.assert_any_call(expected_cached_path)
        mock_makedirs.assert_not_called() # Should not call if already exists
        mock_file_open.assert_not_called() # Should not simulate writing content

    @patch("os.makedirs")
    @patch("builtins.open", new_callable=mock_open)
    @patch("os.path.exists")
    @patch("urllib.parse.urlparse")
    def test_http_asset_caching_first_call(self, mock_urlparse, mock_exists, mock_file_open, mock_makedirs):
        http_asset = HttpAsset(url="https://example.com/test_asset.glb")
        mock_parsed_url = MagicMock()
        mock_parsed_url.path = "/test_asset.glb"
        mock_urlparse.return_value = mock_parsed_url

        filename = os.path.basename(mock_parsed_url.path) # Logic inside _resolve_http_asset
        expected_cached_path = os.path.join(self.test_cache_dir, filename)

        mock_exists.side_effect = lambda path: path == expected_cached_path and False # Not exists initially

        resolved_path = self.resolver._resolve_http_asset(http_asset)
        self.assertEqual(resolved_path, expected_cached_path)
        mock_exists.assert_any_call(expected_cached_path)
        mock_makedirs.assert_called_with(self.test_cache_dir, exist_ok=True) # Ensure cache dir is there
        mock_file_open.assert_called() # Should simulate writing content

    @patch("os.makedirs")
    @patch("builtins.open", new_callable=mock_open)
    @patch("os.path.exists")
    @patch("urllib.parse.urlparse")
    def test_http_asset_caching_second_call(self, mock_urlparse, mock_exists, mock_file_open, mock_makedirs):
        http_asset = HttpAsset(url="https://example.com/test_asset.glb")
        mock_parsed_url = MagicMock()
        mock_parsed_url.path = "/test_asset.glb"
        mock_urlparse.return_value = mock_parsed_url

        filename = os.path.basename(mock_parsed_url.path)
        expected_cached_path = os.path.join(self.test_cache_dir, filename)

        mock_exists.side_effect = lambda path: path == expected_cached_path and True # Already exists

        resolved_path = self.resolver._resolve_http_asset(http_asset)
        self.assertEqual(resolved_path, expected_cached_path)
        mock_exists.assert_any_call(expected_cached_path)
        mock_makedirs.assert_not_called() # Should not create if already exists
        mock_file_open.assert_not_called() # Should not simulate writing content

