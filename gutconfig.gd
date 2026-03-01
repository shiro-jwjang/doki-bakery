# gutconfig.gd - GUT Test Framework Configuration

# 테스트 결과를 저장할 디렉토리
var directory = 'res://test'

# 테스트 스크립트 접두사
var test_prefix = 'test_'

# 테스트 스크립트 접미사
var test_suffix = '.gd'

# 결과 내보내기 (선택사항)
var export_paths = []

# doubled classes를 생성할 디렉토리
var double_directory = 'res://test/doubles'

# partial classes를 생성할 디렉토리
var partial_directory = 'res://test/partial'

# 테스트 실행 시 최대 대기 시간 (초)
var max_wait_time = 10.0

# 테스트 리소스 경로
var resource_path = 'res://test/resources'

# 로그 레벨 (0=모두, 1=실패만, 2=없음)
var log_level = 0
