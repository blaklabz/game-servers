import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from relay import classify

class RelayTests(unittest.TestCase):
    def test_join(self):
        self.assertEqual(classify('Merllinacz has joined the server.'), ('join', 'Merllinacz'))
    def test_leave(self):
        self.assertEqual(classify('Merllinacz has left the server.'), ('leave', 'Merllinacz'))
    def test_ready(self):
        self.assertEqual(classify('Server is now running on port 14159'), ('ready', None))
    def test_unrelated(self):
        self.assertIsNone(classify('Saved world successfully'))

if __name__ == '__main__':
    unittest.main()
