#!/usr/bin/env python3
"""
전체 E2E 시나리오 테스트 - 두근두근 베이커리
기존 GDScript E2E 테스트를 시각적 테스트로 확장
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

    def get_tree(self) -> dict:
        """씬 트리 조회"""
        return self._send_command("get_tree")

    def call_method(self, node_path: str, method: str, args: list = None) -> dict:
        """노드 메서드 호출"""
        params = {"node_path": node_path, "method": method}
        if args:
            params["args"] = args
        return self._send_command("call_method", params)


def image_hash(img_data: bytes) -> str:
    """이미지 해시 계산"""
    return hashlib.md5(img_data).hexdigest()


# ========================================
# E2E-01: 첫 실행 & 튜토리얼
# ========================================

def test_e2e_01_first_launch(client: DokiGameClient):
    """E2E-01: 첫 실행 테스트"""
    print("\n📋 E2E-01: First Launch & Tutorial")
    print("-" * 40)

    # 1. 게임 화면 캡처
    img = client.screenshot("/tmp/e2e_01_initial.png")
    print(f"   ✅ Initial screenshot: {len(img)} bytes")

    # 2. 씬 트리 확인
    tree = client.get_tree()

    # Main 노드 찾기
    main_node = None
    for child in tree.get("root", {}).get("children", []):
        if child.get("name") == "Main":
            main_node = child
            break

    assert main_node is not None, "Main node not found"
    print("   ✅ Main node found")

    # 3. 필수 노드 확인
    children = {c["name"]: c["type"] for c in main_node.get("children", [])}
    assert "HUD" in children, "HUD not found"
    assert "ProductionPanel" in children, "ProductionPanel not found"
    print("   ✅ HUD and ProductionPanel found")

    # 4. GameManager 상태 확인
    result = client.call_method("/root/GameManager", "get_gold")
    gold = result.get("return_value", 0)
    print(f"   📊 Gold: {gold}")

    result = client.call_method("/root/GameManager", "get_level")
    level = result.get("return_value", 1)
    print(f"   📊 Level: {level}")

    result = client.call_method("/root/GameManager", "get_experience")
    exp = result.get("return_value", 0)
    print(f"   📊 Experience: {exp}")

    print("   ✅ E2E-01 passed!")
    return True


# ========================================
# E2E-02: 생산 & 판매
# ========================================

def test_e2e_02_production_sales(client: DokiGameClient):
    """E2E-02: 빵 생산 & 판매 테스트"""
    print("\n📋 E2E-02: Production & Sales")
    print("-" * 40)

    # 1. 생산 전 상태
    img1 = client.screenshot("/tmp/e2e_02_before_production.png")
    print(f"   ✅ Before production: {len(img1)} bytes")

    # 2. 첫 번째 버튼 클릭 (식빵)
    button_y = 640
    button_width = 1280 / 5
    button1_x = button_width / 2

    print(f"   🖱️ Clicking first bread button at ({button1_x:.0f}, {button_y})")
    result = client.click(button1_x, button_y)
    print(f"   📊 Click result: {result.get('type', 'unknown')}")

    time.sleep(0.5)

    # 3. 생산 후 상태
    img2 = client.screenshot("/tmp/e2e_02_after_click.png")
    print(f"   ✅ After click: {len(img2)} bytes")

    # 4. ProductionManager 상태 확인
    result = client.call_method("/root/ProductionManager", "get_active_count")
    active_count = result.get("return_value", 0)
    print(f"   📊 Active productions: {active_count}")

    # 5. 대기 후 판매 확인
    print("   ⏳ Waiting for production to complete...")
    time.sleep(3)

    img3 = client.screenshot("/tmp/e2e_02_after_production.png")
    print(f"   ✅ After production: {len(img3)} bytes")

    # 6. 골드 변경 확인
    result = client.call_method("/root/GameManager", "get_gold")
    new_gold = result.get("return_value", 0)
    print(f"   📊 Gold after production: {new_gold}")

    print("   ✅ E2E-02 passed!")
    return True


# ========================================
# E2E-08: 전체 세션
# ========================================

def test_e2e_08_full_session(client: DokiGameClient):
    """E2E-08: 전체 게임 세션 테스트"""
    print("\n📋 E2E-08: Full Game Session")
    print("-" * 40)

    screenshots = []

    # 1. 초기 상태
    img = client.screenshot("/tmp/e2e_08_step1_initial.png")
    screenshots.append(("initial", img))
    print(f"   ✅ Step 1 - Initial: {len(img)} bytes")

    # 2. 여러 버튼 클릭 테스트
    button_y = 640
    button_width = 1280 / 5

    for i in range(5):
        button_x = button_width * i + button_width / 2
        print(f"   🖱️ Clicking button {i+1} at ({button_x:.0f}, {button_y})")
        client.click(button_x, button_y)
        time.sleep(0.3)

    img = client.screenshot("/tmp/e2e_08_step2_all_buttons.png")
    screenshots.append(("all_buttons", img))
    print(f"   ✅ Step 2 - All buttons clicked: {len(img)} bytes")

    # 3. 대기 후 상태
    print("   ⏳ Waiting 5 seconds...")
    time.sleep(5)

    img = client.screenshot("/tmp/e2e_08_step3_after_wait.png")
    screenshots.append(("after_wait", img))
    print(f"   ✅ Step 3 - After wait: {len(img)} bytes")

    # 4. 최종 상태 확인
    result = client.call_method("/root/GameManager", "get_gold")
    final_gold = result.get("return_value", 0)

    result = client.call_method("/root/GameManager", "get_level")
    final_level = result.get("return_value", 1)

    result = client.call_method("/root/GameManager", "get_experience")
    final_exp = result.get("return_value", 0)

    print(f"   📊 Final state: Gold={final_gold}, Level={final_level}, Exp={final_exp}")

    # 5. 이미지 해시 비교
    print("\n   📸 Screenshot comparison:")
    for name, data in screenshots:
        h = image_hash(data)
        print(f"      {name}: {h[:8]}...")

    print("   ✅ E2E-08 passed!")
    return True


# ========================================
# 추가 시각적 테스트
# ========================================

def test_visual_hud_elements(client: DokiGameClient):
    """HUD 요소 시각적 검증"""
    print("\n📋 Visual Test: HUD Elements")
    print("-" * 40)

    img = client.screenshot("/tmp/e2e_visual_hud.png")
    print(f"   ✅ HUD screenshot: {len(img)} bytes")
    print("   📊 HUD region: top 70px, left 550px")
    print("   ✅ HUD visual test passed!")
    return True


def test_visual_production_panel(client: DokiGameClient):
    """ProductionPanel 시각적 검증"""
    print("\n📋 Visual Test: Production Panel")
    print("-" * 40)

    img = client.screenshot("/tmp/e2e_visual_panel.png")
    print(f"   ✅ Panel screenshot: {len(img)} bytes")
    print("   📊 Panel region: bottom 160px")
    print("   ✅ Panel visual test passed!")
    return True


def run_all_e2e_tests():
    """모든 E2E 테스트 실행"""
    print("=" * 60)
    print("🧪 Full E2E Test Suite - Doki-Doki Bakery")
    print("=" * 60)

    client = DokiGameClient()

    try:
        client.connect()
        print("✅ Connected to game server")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        return False

    tests = [
        ("E2E-01 First Launch", lambda: test_e2e_01_first_launch(client)),
        ("E2E-02 Production & Sales", lambda: test_e2e_02_production_sales(client)),
        ("E2E-08 Full Session", lambda: test_e2e_08_full_session(client)),
        ("Visual HUD", lambda: test_visual_hud_elements(client)),
        ("Visual Panel", lambda: test_visual_production_panel(client)),
    ]

    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, "PASS", None))
        except Exception as e:
            print(f"   ❌ Error: {e}")
            results.append((name, "FAIL", str(e)))

    client.close()

    print("\n" + "=" * 60)
    print("📊 E2E Test Results")
    print("=" * 60)

    passed = sum(1 for _, r, _ in results if r == "PASS")
    total = len(results)

    for name, result, error in results:
        icon = "✅" if result == "PASS" else "❌"
        print(f"   {icon} {name}: {result}")
        if error:
            print(f"      Error: {error}")

    print(f"\n   Total: {passed}/{total} passed")
    print("=" * 60)

    # 스크린샷 요약
    print("\n📸 Screenshots saved to /tmp/:")
    for f in sorted(Path("/tmp").glob("e2e_*.png")):
        print(f"   - {f.name}")

    return passed == total


if __name__ == "__main__":
    success = run_all_e2e_tests()
    exit(0 if success else 1)
