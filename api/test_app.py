import unittest
import xml.etree.ElementTree as ET

from app import app


class AvatarTests(unittest.TestCase):
    def setUp(self):
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_customization_options(self):
        response = self.client.get("/api/avatar/spec")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.is_json)

        data = response.get_json()
        self.assertIn("eyes", data["groups"]["facial_features"])
        eye_type = data["parts"]["eyes"]
        self.assertIn("HEART", data["values"][eye_type])

    def test_avatar_generation(self):
        response = self.client.get("/api/avatar?eyes=HEART")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.mimetype, "image/svg+xml")

        root = ET.fromstring(response.data)
        self.assertEqual(root.tag, "{http://www.w3.org/2000/svg}svg")


if __name__ == "__main__":
    unittest.main()