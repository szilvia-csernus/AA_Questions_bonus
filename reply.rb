require_relative "questions_db"
require_relative "model_superclass"
require_relative "question_follow"
require_relative "question_like"
require_relative "user"
require_relative "question"

class Reply < ModelSuperclass

    def self.find_by_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            replies
        WHERE
            question_id = ?
        SQL
        results.map { |result| Reply.new(result)}
    end

    def self.find_by_parent_reply(parent_reply)
        results = QuestionsDatabase.instance.execute(<<-SQL, parent_reply)
        SELECT 
            * 
        FROM 
            replies
        WHERE
            parent_reply = ?
        SQL
        results.map { |result| Reply.new(result)}
    end

    def self.find_by_user_id(user_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT 
            * 
        FROM 
            replies
        WHERE
            user_id = ?
        SQL
        results.map { |result| Reply.new(result)}
    end

    attr_accessor :id, :question_id, :parent_reply, :user_id, :body

    def initialize(hash = {})
        @id = hash['id']
        @question_id = hash['question_id']
        @parent_reply = hash['parent_reply']
        @user_id = hash['user_id']
        @body = hash['body']
    end

    def author
        User.find_by_id(@user_id)
    end

    def question
        Question.find_by_id(@question_id)
    end

    def parent_reply
        Reply.find_by_id(@parent_reply)
    end

    def child_replies
        Reply.find_by_parent_reply(@id)
    end

end