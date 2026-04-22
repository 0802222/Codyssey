import os
import json
import random
from Quiz import STATE_FILE
from Quiz import Quiz, DEFAULT_QUIZZES


class QuizGame:

    def __init__(self):
        self.quizzes = []       # Quiz 목록
        self.best_score = 0     # 최고 점수 (0~100)
        self.load_state()


    # 파일 저장 / 불러오기
    def load_state(self):
        
        # state.json 파일이 없으면 DEFAULT_QUIZZES 로드
        if not os.path.exists(STATE_FILE):
            self._load_defaults()
            print("Python 퀴즈 시작!")
            return

        # state.json 파일이 존재하면 데이터를 불러오고, 오류 발생 시 기본 데이터로 초기화
        """
        - 'r' : 읽기모드
        - encoding="utf-8" : UTF-8 인코딩으로 파일을 읽음 (한글 지원)
        - json.load(f) : JSON 형식의 데이터를 Python 객체로 변환하여 반환
        """
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)

            # quizzes 키의 리스트를 Quiz 객체 리스트로 변환하여 self.quizzes에 저장
            self.quizzes = [Quiz.from_dict(q) for q in data.get("quizzes", [])]
            
            # best_score 키의 값을 정수로 변환하여 self.best_score에 저장, 없으면 0으로 초기화
            self.best_score = int(data.get("best_score", 0))
            
            print(
                f"📂 저장된 데이터를 불러왔습니다. "
                f"(퀴즈 {len(self.quizzes)}개, 최고점수 {self.best_score}점)"
            )

        except json.JSONDecodeError:
            msg = "⚠️ JSON 데이터 파일이 손상되었습니다. 기본 데이터로 초기화합니다."
        except (KeyError) as e:
            msg = f"⚠️ 해당 key가 없습니다. ({e}). 기본 데이터로 초기화합니다."
        except (TypeError) as e:
            msg = f"⚠️ 리스트/딕셔너리가 아닙니다. ({e}). 기본 데이터로 초기화합니다."
        except (ValueError) as e:
            msg = f"⚠️ 정수 변환에 실패했습니다. ({e}). 기본 데이터로 초기화합니다."
        except OSError as e:
            msg = f"⚠️ 파일 읽기 실패 : 권한이 없거나, 디스크 오류 입니다. ({e}). 기본 데이터를 사용합니다."
        else:
            msg = None
        
        if msg:
            print(msg)
            self._load_defaults()


    # 기본 퀴즈 데이터를 로드
    def _load_defaults(self):
        
        # DEFAULT_QUIZZES 리스트의 각 딕셔너리를 Quiz 객체로 변환하여 self.quizzes에 저장
        self.quizzes = [Quiz.from_dict(q) for q in DEFAULT_QUIZZES]
        self.best_score = 0


    # 퀴즈와 최고 점수를 state.json에 저장
    def save_state(self):
    
        data = {
            "quizzes": [q.to_dict() for q in self.quizzes],
            "best_score": self.best_score
        }

        # JSON 파일로 저장
        """
        - 'w' : 쓰기모드 (파일이 없으면 새로 생성, 있으면 덮어쓰기)
        - json.dump() : Python 객체를 JSON 형식으로 변환하여 파일에 저장
        - ensure_ascii=False : JSON 파일에 한글이 그대로 저장되도록 설정 (유니코드 이스케이프 방지)
        """
        try:
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except OSError as e:
            print(f"⚠️ 파일 저장 오류 ({e}). 데이터가 저장되지 않았습니다.")
            