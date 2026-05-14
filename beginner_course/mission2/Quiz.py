import json
import os
import random

# 게임의 상태, 누적 데이터, 사용자가 추가한 게임을 저장하는 파일
STATE_FILE = "state.json"

# 기본 퀴즈 (주제: Python 기초)
DEFAULT_QUIZZES = [
    {
        "question": "Python을 만든 사람은 누구인가요?",
        "choices": ["귀도 반 로섬", "리누스 토르발스", "제임스 고슬링", "빌 게이츠"],
        "answer": 1
    },
    {
        "question": "Python에서 리스트(list)를 만들 때 사용하는 괄호는?",
        "choices": ["( )", "{ }", "[ ]", "< >"],
        "answer": 3
    },
    {
        "question": "Python에서 주석을 표시할 때 사용하는 기호는?",
        "choices": ["//", "#", "/*", "--"],
        "answer": 2
    },
    {
        "question": "Python에서 함수를 정의할 때 사용하는 키워드는?",
        "choices": ["function", "func", "def", "define"],
        "answer": 3
    },
    {
        "question": "Python에서 True와 False를 다루는 자료형은?",
        "choices": ["int", "str", "float", "bool"],
        "answer": 4
    }
]

class Quiz:

    def __init__(self, question, choices, answer):
        self.question = question # 문제
        self.choices = choices   # 선택지 리스트 (4개)
        self.answer = answer     # 정답지


    # 문제와 선택지를 출력
    def display(self, index=None):

        if index is not None:
            print(f"\n[문제 {index}]")
        print(self.question)
        print()

        # enumerate 는 리스트의 요소(선택지)와 인덱스를 함께 반환하는 함수 (1부터 시작)
        for i, choice in enumerate(self.choices, 1):
            print(f"  {i}. {choice}")


    # 정답 여부를 반환 (True/False)
    def check_answer(self, user_answer):
        return user_answer == self.answer


    # JSON 저장을 위해 객체를 딕셔너리로 변환
    def to_dict(self):
        return {
            "question": self.question,
            "choices": self.choices,
            "answer": self.answer
        }


    """ 
    - @classmethod : 인스턴스 메서드가 아닌 클래스 메서드로 정의, cls는 Quiz클래스 자체를 가리킴
    - 클래스 메서드 안에서 cls()를 호출하면 Quiz 클래스의 새로운 인스턴스를 생성할 수 있음
    """
    # data 딕셔너리에서 question, choices, answer를 꺼내서 Quiz 객체를 생성
    @classmethod
    def from_dict(cls, data):
        return cls(data["question"], data["choices"], data["answer"])