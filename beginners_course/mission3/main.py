import json
import time
from typing import List, Dict, Optional

EPSILON = 1e-9
PERF_REPEAT = 10


def normalize_label(value: str) -> Optional[str]:
    if value is None:
        return None

    text = str(value).strip().lower()

    if text in ["+", "cross"]:
        return "Cross"
    if text in ["x"]:
        return "X"

    return None


def parse_size_from_key(key: str) -> Optional[int]:
    parts = key.split("_")
    if len(parts) < 3:
        return None
    if parts[0] != "size":
        return None

    try:
        return int(parts[1])
    except ValueError:
        return None


def is_square_matrix(matrix: List[List[float]], n: int) -> bool:
    if not isinstance(matrix, list) or len(matrix) != n:
        return False

    for row in matrix:
        if not isinstance(row, list) or len(row) != n:
            return False

    return True


def mac(pattern: List[List[float]], filter: List[List[float]]) -> float:
    n = len(pattern)
    total = 0.0

    for i in range(n):
        for j in range(n):
            total += pattern[i][j] * filter[i][j]

    return total


def decide_label(score_cross: float, score_x: float, epsilon: float = EPSILON) -> str:
    if abs(score_cross - score_x) < epsilon:
        return "UNDECIDED"
    return "Cross" if score_cross > score_x else "X"


def measure_mac_time(pattern: List[List[float]], filter: List[List[float]], repeat: int = PERF_REPEAT) -> float:
    times = []

    for _ in range(repeat):
        start = time.perf_counter()
        mac(pattern, filter)
        end = time.perf_counter()
        times.append((end - start) * 1000.0)

    return sum(times) / len(times)


def input_matrix(n: int, title: str) -> List[List[float]]:
    print(title)
    matrix = []

    row_idx = 0
    while row_idx < n:
        raw = input().strip()
        parts = raw.split()

        if len(parts) != n:
            print(f"입력 형식 오류: 각 줄에 {n}개의 숫자를 공백으로 구분해 입력하세요.")
            continue

        try:
            row = [float(x) for x in parts]
        except ValueError:
            print(f"입력 형식 오류: 각 줄에 {n}개의 숫자를 공백으로 구분해 입력하세요.")
            continue

        matrix.append(row)
        row_idx += 1

    return matrix


def print_matrix_saved(name: str, matrix: List[List[float]]) -> None:
    print(f"✓ {name} 저장 완료")
    for row in matrix:
        print(" ".join(str(x) for x in row))


def generate_cross_pattern(n: int) -> List[List[float]]:
    matrix = [[0.0 for _ in range(n)] for _ in range(n)]
    mid = n // 2

    for i in range(n):
        matrix[i][mid] = 1.0
        matrix[mid][i] = 1.0

    return matrix


def generate_x_pattern(n: int) -> List[List[float]]:
    matrix = [[0.0 for _ in range(n)] for _ in range(n)]

    for i in range(n):
        matrix[i][i] = 1.0
        matrix[i][n - 1 - i] = 1.0

    return matrix


def analyze_single_case(case_id: str,
                        pattern: List[List[float]],
                        cross_filter: List[List[float]],
                        x_filter: List[List[float]],
                        expected_raw: str) -> Dict:
    expected = normalize_label(expected_raw)

    if expected is None:
        return {
            "case_id": case_id,
            "status": "FAIL",
            "reason": f"expected 라벨 정규화 실패: {expected_raw}",
            "predicted": "INVALID",
            "expected": str(expected_raw),
            "cross_score": None,
            "x_score": None
        }

    n = len(pattern)

    if not is_square_matrix(pattern, n):
        return {
            "case_id": case_id,
            "status": "FAIL",
            "reason": "패턴이 올바른 정사각형 2차원 배열이 아님",
            "predicted": "INVALID",
            "expected": expected,
            "cross_score": None,
            "x_score": None
        }

    if not is_square_matrix(cross_filter, n) or not is_square_matrix(x_filter, n):
        return {
            "case_id": case_id,
            "status": "FAIL",
            "reason": "필터와 패턴 크기 불일치",
            "predicted": "INVALID",
            "expected": expected,
            "cross_score": None,
            "x_score": None
        }

    cross_score = mac(pattern, cross_filter)
    x_score = mac(pattern, x_filter)
    predicted = decide_label(cross_score, x_score, EPSILON)
    status = "PASS" if predicted == expected else "FAIL"

    reason = ""
    if status == "FAIL":
        if predicted == "UNDECIDED":
            reason = "동점(UNDECIDED) 처리 규칙에 따라 FAIL"
        else:
            reason = f"예상값과 판정 불일치: expected={expected}, predicted={predicted}"

    return {
        "case_id": case_id,
        "status": status,
        "reason": reason,
        "predicted": predicted,
        "expected": expected,
        "cross_score": cross_score,
        "x_score": x_score
    }


def run_manual_mode() -> None:
    print("\n#----------------------------------------")
    print("# [1] 필터 입력")
    print("#----------------------------------------")
    filter_a = input_matrix(3, "필터 A (3줄 입력, 공백 구분)")
    print()
    filter_b = input_matrix(3, "필터 B (3줄 입력, 공백 구분)")

    print()
    print_matrix_saved("필터 A", filter_a)
    print_matrix_saved("필터 B", filter_b)

    print("\n#----------------------------------------")
    print("# [2] 패턴 입력")
    print("#----------------------------------------")
    pattern = input_matrix(3, "패턴 (3줄 입력, 공백 구분)")

    score_a = mac(pattern, filter_a)
    score_b = mac(pattern, filter_b)

    avg_a = measure_mac_time(pattern, filter_a, PERF_REPEAT)
    avg_b = measure_mac_time(pattern, filter_b, PERF_REPEAT)
    avg_ms = (avg_a + avg_b) / 2.0

    print("\n#----------------------------------------")
    print("# [3] MAC 결과")
    print("#----------------------------------------")
    print(f"A 점수: {score_a}")
    print(f"B 점수: {score_b}")
    print(f"연산 시간(평균/{PERF_REPEAT}회): {avg_ms:.6f} ms")

    if abs(score_a - score_b) < EPSILON:
        print(f"판정: 판정 불가 (|A-B| < {EPSILON})")
    else:
        print("판정: A" if score_a > score_b else "판정: B")

    print("\n#----------------------------------------")
    print("# [4] 성능 분석")
    print("#----------------------------------------")
    print("크기       평균 시간(ms)    연산 횟수")
    print("-------------------------------------")
    print(f"3x3        {avg_ms:>12.6f}    {3 * 3:>8}")


def load_json_data(file_path: str = "data.json") -> Dict:
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def extract_filters(data: Dict) -> Dict[int, Dict[str, List[List[float]]]]:
    result = {}
    filters = data.get("filters", {})

    for size_key, label_map in filters.items():
        if not size_key.startswith("size_"):
            continue

        try:
            n = int(size_key.split("_")[1])
        except (IndexError, ValueError):
            continue

        result[n] = {}

        for raw_label, matrix in label_map.items():
            normalized = normalize_label(raw_label)
            if normalized is not None:
                result[n][normalized] = matrix

    return result


def run_json_mode() -> None:
    try:
        data = load_json_data("data.json")
    except FileNotFoundError:
        print("오류: data.json 파일을 찾을 수 없습니다.")
        return
    except json.JSONDecodeError as e:
        print(f"오류: data.json 파싱 실패 - {e}")
        return

    filters_by_size = extract_filters(data)
    patterns = data.get("patterns", {})

    print("\n#----------------------------------------")
    print("# [1] 필터 로드")
    print("#----------------------------------------")

    for n in sorted(filters_by_size.keys()):
        has_cross = "Cross" in filters_by_size[n]
        has_x = "X" in filters_by_size[n]
        if has_cross and has_x:
            print(f"✓ size_{n} 필터 로드 완료 (Cross, X)")
        else:
            print(f"⚠ size_{n} 필터 일부 누락")

    print("\n#----------------------------------------")
    print("# [2] 패턴 분석 (라벨 정규화 적용)")
    print("#----------------------------------------")

    results = []

    for case_id, item in patterns.items():
        print(f"--- {case_id} ---")

        n = parse_size_from_key(case_id)
        if n is None:
            result = {
                "case_id": case_id,
                "status": "FAIL",
                "reason": "패턴 키 규칙 오류: size_N_idx 형태가 아님",
                "predicted": "INVALID",
                "expected": str(item.get("expected")),
                "cross_score": None,
                "x_score": None
            }
            results.append(result)
            print(f"FAIL - {result['reason']}")
            continue

        if n not in filters_by_size:
            result = {
                "case_id": case_id,
                "status": "FAIL",
                "reason": f"size_{n} 필터 없음",
                "predicted": "INVALID",
                "expected": str(item.get("expected")),
                "cross_score": None,
                "x_score": None
            }
            results.append(result)
            print(f"FAIL - {result['reason']}")
            continue

        cross_filter = filters_by_size[n].get("Cross")
        x_filter = filters_by_size[n].get("X")

        if cross_filter is None or x_filter is None:
            result = {
                "case_id": case_id,
                "status": "FAIL",
                "reason": f"size_{n} 필터의 Cross/X 라벨 누락",
                "predicted": "INVALID",
                "expected": str(item.get("expected")),
                "cross_score": None,
                "x_score": None
            }
            results.append(result)
            print(f"FAIL - {result['reason']}")
            continue

        pattern = item.get("input")
        expected = item.get("expected")

        result = analyze_single_case(case_id, pattern, cross_filter, x_filter, expected)
        results.append(result)

        if result["cross_score"] is not None and result["x_score"] is not None:
            print(f"Cross 점수: {result['cross_score']}")
            print(f"X 점수: {result['x_score']}")
            print(
                f"판정: {result['predicted']} | expected: {result['expected']} | {result['status']}"
            )
            if result["status"] == "FAIL":
                print(f"사유: {result['reason']}")
        else:
            print(f"FAIL - {result['reason']}")

    print("\n#----------------------------------------")
    print("# [3] 성능 분석 (평균/10회)")
    print("#----------------------------------------")
    print("크기       평균 시간(ms)    연산 횟수")
    print("-------------------------------------")

    sizes = [3, 5, 13, 25]
    for n in sizes:
        sample_pattern = generate_cross_pattern(n)
        sample_filter = generate_cross_pattern(n)
        avg_ms = measure_mac_time(sample_pattern, sample_filter, PERF_REPEAT)
        print(f"{n}x{n}      {avg_ms:>12.6f}    {n * n:>8}")

    total = len(results)
    passed = sum(1 for r in results if r["status"] == "PASS")
    failed = total - passed

    print("\n#----------------------------------------")
    print("# [4] 결과 요약")
    print("#----------------------------------------")
    print(f"총 테스트: {total}개")
    print(f"통과: {passed}개")
    print(f"실패: {failed}개")

    if failed > 0:
        print("\n실패 케이스:")
        for r in results:
            if r["status"] == "FAIL":
                print(f"- {r['case_id']}: {r['reason']}")


def main() -> None:
    print("=== Mini NPU Simulator ===")
    print("\n[모드 선택]")
    print("1. 사용자 입력 (3x3)")
    print("2. data.json 분석")

    while True:
        choice = input("선택: ").strip()

        if choice == "1":
            run_manual_mode()
            break
        elif choice == "2":
            run_json_mode()
            break
        else:
            print("입력 오류: 1 또는 2를 입력하세요.")


if __name__ == "__main__":
    main()