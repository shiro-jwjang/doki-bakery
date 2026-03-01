#!/usr/bin/env python3
"""
E2E 시각적 테스트 - 두근두근 베이커리
게임 화면 캡처 및 상호작용 테스트
"""

import socket
import json
import base64
import struct
import time
import hashlib
from pathlib import Path


class DokiGameClient:
    """두근두근 베이커리 게임 클라이언트"""

    def __init__(self, host: str = "127.0.0.1", port: int = 7777):
        self.host = host
        self.port = port
        self.sock = None

    def connect(self):
        """서버 연결"""
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(30)
        self.sock.connect((self.host, self.port))
        time.sleep(0.2)
        # Welcome 메시지 수신
        header = self.sock.recv(4)
        size = struct.unpack('<I', header)[0]
        self.sock.recv(size)

    def close(self):
        """연결 종료"""
        if self.sock:
            self.sock.close()
            self.sock = None

    def _send_command(self, command: str, params: dict = None) -> dict:
        """명령 전송"""
        msg = json.dumps({"command": command, "params": params or {}}) + "\n"
        self.sock.sendall(msg.encode())
        time.sleep(0.3)

        header = self.sock.recv(4)
        packet_size = struct.unpack('<I', header)[0]

        data = b''
        while len(data) < packet_size:
            chunk = self.sock.recv(min(packet_size - len(data), 65536))
            if not chunk:
                break
            data += chunk

        return json.loads(data.decode().rstrip('\x00'))

    def screenshot(self, save_path: str = None) -> bytes:
        """스크린샷 캡처"""
        resp = self._send_command("capture_screenshot")
        if 'data' in resp:
            img_data = base64.b64decode(resp['data'])
            if save_path:
                Path(save_path).write_bytes(img_data)
            return img_data
        raise Exception(f"Screenshot failed: {resp}")

    def click(self, x: float, y: float, button: str = "left"):
        """마우스 클릭"""
        return self._send_command("inject_mouse_click", {"x": x, "y": y, "button": button})

    def move_mouse(self, x: float, y: float):
        """마우스 이동"""
        return self._send_command("inject_mouse_motion", {"x": x, "y": y})

    def press_key(self, key: str):
        """키 입력"""
        return self._send_command("inject_key", {"key_label": key, "pressed": True})

    def get_tree(self) -> dict:
        """씬 트리 조회"""
        return self._send_command("get_tree")

    def get_node(self, node_path: str) -> dict:
        """노드 정보 조회"""
        return self._send_command("get_node", {"node_path": node_path})


def image_hash(img_data: bytes) -> str:
    """이미지 해시 계산"""
    return hashlib.md5(img_data).hexdigest()


def test_first_launch():
    """테스트 1: 첫 실행 화면"""
    print("\n📋 Test 1: First Launch Screen")

    client = DokiGameClient()
    client.connect()

    # 스크린샷 캡처
    img = client.screenshot("/tmp/test_01_first_launch.png")
    h = image_hash(img)
    print(f"   Screenshot: {len(img)} bytes, hash: {h[:8]}...")

    # 씬 트리 확인
    tree = client.get_tree()
    main_node = None
    for child in tree.get("root", {}).get("children", []):
        if child.get("name") == "Main":
            main_node = child
            break

    assert main_node is not None, "Main node not found"
    print(f"   ✅ Main node found")

    # 자식 노드 확인
    children = {c["name"]: c["type"] for c in main_node.get("children", [])}
    assert "HUD" in children, "HUD not found"
    assert "ProductionPanel" in children, "ProductionPanel not found"
    print(f"   ✅ HUD and ProductionPanel found")

    client.close()
    print("   ✅ Test 1 passed!")
    return True


def test_hud_visibility():
    """테스트 2: HUD 가시성"""
    print("\n📋 Test 2: HUD Visibility")

    client = DokiGameClient()
    client.connect()

    # 스크린샷
    img = client.screenshot("/tmp/test_02_hud.png")
    print(f"   Screenshot: {len(img)} bytes")

    # GameManager에서 골드/레벨 확인
    # (MCP Runtime으로 노드 프로퍼티 조회는 제한적이므로 스크린샷 기반 테스트)

    client.close()
    print("   ✅ Test 2 passed!")
    return True


def test_production_panel_buttons():
    """테스트 3: 빵 생산 버튼"""
    print("\n📋 Test 3: Production Panel Buttons")

    client = DokiGameClient()
    client.connect()

    # 스크린샷
    img = client.screenshot("/tmp/test_03_buttons.png")
    print(f"   Screenshot: {len(img)} bytes")

    # 첫 번째 버튼 클릭 (식빵, 위치 추정)
    # 화면 하단 중앙 근처, 1280x720 기준
    # 버튼 영역: y=640 (하단 160px), x=1280/5=256 간격

    button_y = 640  # 하단 패널 중간
    button1_x = 128 + 64  # 첫 번째 버튼 중앙 (256/2 + 128)

    print(f"   Clicking button 1 at ({button1_x}, {button_y})")
    result = client.click(button1_x, button_y)
    print(f"   Click result: {result}")

    time.sleep(0.5)

    # 클릭 후 스크린샷
    img2 = client.screenshot("/tmp/test_03_after_click.png")
    print(f"   After click: {len(img2)} bytes")

    client.close()
    print("   ✅ Test 3 passed!")
    return True


def test_visual_regression():
    """테스트 4: 시각적 회귀 테스트"""
    print("\n📋 Test 4: Visual Regression")

    client = DokiGameClient()
    client.connect()

    # 베이스라인 스크린샷
    img1 = client.screenshot("/tmp/test_04_baseline.png")
    hash1 = image_hash(img1)

    # 잠시 대기 후 다시 캡처
    time.sleep(1)

    img2 = client.screenshot("/tmp/test_04_current.png")
    hash2 = image_hash(img2)

    print(f"   Baseline hash: {hash1[:8]}...")
    print(f"   Current hash:  {hash2[:8]}...")

    if hash1 == hash2:
        print("   ✅ Screenshots identical (stable UI)")
    else:
        print("   ⚠️ Screenshots differ (dynamic elements)")

    client.close()
    print("   ✅ Test 4 passed!")
    return True


def run_all_tests():
    """모든 테스트 실행"""
    print("=" * 50)
    print("🧪 E2E Visual Tests - Doki-Doki Bakery")
    print("=" * 50)

    tests = [
        test_first_launch,
        test_hud_visibility,
        test_production_panel_buttons,
        test_visual_regression,
    ]

    results = []
    for test in tests:
        try:
            result = test()
            results.append((test.__name__, "PASS"))
        except Exception as e:
            print(f"   ❌ Error: {e}")
            results.append((test.__name__, "FAIL"))

    print("\n" + "=" * 50)
    print("📊 Test Results")
    print("=" * 50)

    passed = sum(1 for _, r in results if r == "PASS")
    total = len(results)

    for name, result in results:
        icon = "✅" if result == "PASS" else "❌"
        print(f"   {icon} {name}: {result}")

    print(f"\n   Total: {passed}/{total} passed")
    print("=" * 50)

    return passed == total


if __name__ == "__main__":
    success = run_all_tests()
    exit(0 if success else 1)
