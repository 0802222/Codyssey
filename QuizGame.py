import datetime
import os
import json
import random
from Quiz import STATE_FILE
from Quiz import Quiz, DEFAULT_QUIZZES


class QuizGame:

    def __init__(self):
        self.quizzes = []          
        self.best_score = 0        
        self.best_score_date = ""
        self.nickname = ""         
        self.best_nickname = ""   
        self.players = []
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

            # best_nickname 키의 값을 문자열로 변환하여 self.best_nickname에 저장, 없으면 빈 문자열로 초기화
            self.best_nickname = str(data.get("best_nickname", ""))

            # best_score_date 키의 값을 문자열로 변환하여 self.best_score_date에 저장, 없으면 빈 문자열로 초기화
            self.best_score_date = str(data.get("best_score_date", ""))

            # players 키의 리스트를 문자열 리스트로 변환하여 self.players에 저장, 없으면 빈 리스트로 초기화
            self.players = data.get("players", [])
            
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
            "best_score": self.best_score,
            "best_nickname": self.best_nickname,
            "best_score_date": self.best_score_date,
            "players": self.players
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


    # 최고 점수 출력
    def show_score(self):
        
        print("\n" + "=" * 30)
        if self.best_score == 0:
            print("아직 퀴즈를 풀지 않았습니다.")
        else:
            print("🏆 명예의 전당 🏆")
            print(f"🏆 닉네임: {self.best_nickname}님")
            print(f"🏆 최고 점수: {self.best_score}점")
            if self.best_score_date:
                print(f"🏆 등재일: {self.best_score_date}")
        print("=" * 30)


    # 메뉴 출력
    def show_menu(self):
        
        print("\n" + "=" * 30)
        print("     Python Quiz Game ")
        print("=" * 30)
        print("\n  1. 퀴즈 풀기")
        print("\n  2. 퀴즈 추가")
        print("\n  3. 퀴즈 목록")
        print("\n  4. 점수 확인")
        print("\n  5. 종료\n")
        print("=" * 30)
        print()


    # 게임 메인 루프. Ctrl+C / EOF 발생 시 안전하게 종료
    def run(self):
        
        # 닉네임 입력받기
        while True:
            try:
                self.nickname = self.get_str_input("닉네임을 입력하세요: ")
            except KeyboardInterrupt:
                print("\n\n⚠️ Ctrl+C 감지!!! 데이터를 저장하고 종료합니다.")
                self.save_state()
                return
            except EOFError:
                print("\n\n⚠️ 입력 스트림 종료(Ctrl+D)!!! 데이터를 저장하고 종료합니다.")
                self.save_state()
                return
            
            if self.is_duplicate_nickname(self.nickname):
                print("\n⚠️ 이미 사용중인 닉네임입니다. 다른 닉네임을 입력해주세요!")
                continue
            
            self.nickname = self.nickname.strip().lower()
            self.players.append(self.nickname)
            self.save_state()
            break

        print(f"\n안녕하세요, {self.nickname} 님!")

        # 메뉴 보여주기
        while True:
            try:
                self.show_menu()
                choice = self.get_int_input(">> : ", 1, 5)

                if choice == 1:
                    self.play_quiz()
                elif choice == 2:
                    self.add_quiz()
                elif choice == 3:
                    self.show_quiz_list()
                elif choice == 4:
                    self.show_score()
                elif choice == 5:
                    print("\n퀴즈가 종료되었습니다. 데이터를 저장합니다.")
                    self.save_state()
                    break

            # get_int_input / get_str_input에서 raised 된 에러를 run()에서 잡아서 처리
            except KeyboardInterrupt:
                print("\n\n⚠️ Ctrl+C 감지!!! 데이터를 저장하고 종료합니다.")
                self.save_state()
                break

            except EOFError:
                print("\n\n⚠️ 입력 스트림 종료(Ctrl+D)!!! 데이터를 저장하고 종료합니다.")
                self.save_state()
                break


    # 퀴즈 출제(순서 랜덤) 및 결과 표시
    def play_quiz(self):
        
        if not self.quizzes:
            print("\n⚠️ 등록된 퀴즈가 없습니다. 먼저 퀴즈를 추가해 주세요.")
            return

        quiz_list = self.quizzes.copy()
        
        # 퀴즈 출제(순서 랜덤)
        random.shuffle(quiz_list)
        
        total = len(quiz_list)

        print()
        print(f"\n📝 퀴즈를 시작합니다! (총 {total} 문제)")

        correct_count = 0
        for i, quiz in enumerate(quiz_list, 1):
            print("\n" + "=" * 30)
            quiz.display(i)

            user_answer = self.get_int_input("\n정답 입력 (1 ~ 4): ", 1, 4)

            if quiz.check_answer(user_answer):
                print("✅ 정답입니다!")
                correct_count += 1
            else:
                correct_text = quiz.choices[quiz.answer - 1]
                print(f"❌ 오답입니다. 정답은 {quiz.answer}번 '{correct_text}'입니다.")


        # 점수 계산
        score = int(correct_count / total * 100)
        print("\n" + "=" * 30)

        # 결과 출력
        user = self.nickname
        print(f"🏆 {user} 님의 결과: {total}문제 중 {correct_count}문제 정답 ({score}점)")

        # 명예의 전당 등재 여부
        """
        - 동점 처리 규칙 : 최고 점수보다 크거나 같으면 갱신 (가장 최근에 달성한 사람이 명예의 전당에 등재)
        """
        if score >= self.best_score:
            self.best_score = score
            self.best_nickname = self.nickname
            self.best_score_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"🎉 {self.best_nickname}님이 새로운 최고 점수를 기록했습니다!")
        else:
            print(f"현재 최고 점수: {self.best_score}점")

        print("=" * 30)
        
        # 저장
        self.save_state()


    # 등록된 퀴즈 목록 출력
    def show_quiz_list(self):
        
        if not self.quizzes:
            print("\n⚠️ 등록된 퀴즈가 없습니다.")
            return

        print(f"\n📋 등록된 퀴즈 목록 (총 {len(self.quizzes)} 개)")
        print("=" * 30)
        for i, quiz in enumerate(self.quizzes, 1):
            print(f"[{i}] {quiz.question}")
        print("=" * 30)


    # 퀴즈 추가
    def add_quiz(self):
        print("\n+ 새로운 퀴즈를 추가합니다.")

        question = self.get_str_input("\n문제를 입력하세요: ")

        # 선택지 입력
        choices = []
        for i in range(1, 5):
            choice = self.get_str_input(f"선택지 {i}: ")
            choices.append(choice)

        answer = self.get_int_input("정답 번호 (1 ~ 4): ", 1, 4)

        self.quizzes.append(Quiz(question, choices, answer))
        
        # 저장
        self.save_state()

        print("\n✅ 퀴즈가 추가되었습니다!")

    
    # 입력 유효성 검사 메서드(정수)
    def get_int_input(self, prompt, min_val, max_val):
        """
        유효한 정수를 입력받는다.
        - 앞뒤 공백 자동 제거
        - 빈 입력, 숫자 아닌 값, 범위 밖 값은 재입력 요청
        - KeyboardInterrupt / EOFError는 상위로 전파
        """
        while True:
            try:
                raw = input(prompt).strip()
            except (KeyboardInterrupt, EOFError):
                raise # 여기서 처리하지 않고 상위로 던짐

            if not raw:
                print(f"⚠️ 입력이 비어 있습니다. {min_val} ~ {max_val} 사이의 숫자를 입력하세요.")
                continue

            try:
                value = int(raw)
            except ValueError:
                print(f"⚠️ 잘못된 입력입니다. {min_val} ~ {max_val} 사이의 숫자를 입력하세요.")
                continue

            if value < min_val or value > max_val:
                print(f"⚠️ {min_val} ~ {max_val} 사이의 숫자를 입력하세요.")
                continue

            return value


    # 입력 유효성 검사 메서드(문자열)
    def get_str_input(self, prompt):
        """
        - 앞뒤 공백 자동 제거
        - 빈 입력은 재입력 요청
        """
        while True:
            try:
                raw = input(prompt).strip()
            except (KeyboardInterrupt, EOFError):
                raise # 여기서 처리하지 않고 상위로 던짐

            if not raw:
                print("⚠️ 입력이 비어 있습니다. 다시 입력하세요.")
                continue

            return raw    

    # 닉네임 정규화
    def normalize_nickname(self, nickname):
        return nickname.strip().lower()
    
    # 닉네임 중복 방지
    def is_duplicate_nickname(self, nickname):
        new_name = self.normalize_nickname(nickname)
        return any(
            new_name == self.normalize_nickname(player) 
            for player in self.players
        )