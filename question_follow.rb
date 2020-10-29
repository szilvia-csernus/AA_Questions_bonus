require_relative "questions_db"
require_relative "model_superclass"
require_relative "user"
require_relative "question"

class QuestionFollow < ModelSuperclass

    def self.find_by_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            question_follows
        WHERE
            question_id = ?
        SQL
        results.map { |result| QuestionFollow.new(result)}
    end

    def self.find_by_follower_id(follower_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, follower_id)
        SELECT 
            * 
        FROM 
            question_follows
        WHERE
            follower_id = ?
        SQL
        results.map { |result| QuestionFollow.new(result)}
    end

    def self.followers_for_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            users
        JOIN
            question_follows ON question_follows.follower_id = users.id
        WHERE
            question_id = ?
        SQL
        results.map { |result| User.new(result)}
    end

    def self.followed_questions_for_user_id(user_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT 
            * 
        FROM 
            questions
        JOIN
            question_follows ON question_follows.question_id = questions.id
        WHERE
            follower_id = ?
        SQL
        results.map { |result| Question.new(result)}
    end

    def self.most_followed_questions(n)
        results = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            *
        FROM
            questions
        JOIN
            (SELECT 
                questions.id, COUNT(question_follows.follower_id) AS count
            FROM 
                questions
            JOIN
                question_follows 
                ON question_follows.question_id = questions.id
            GROUP BY questions.id

            ) follower_count
        ON questions.id = follower_count.id
        ORDER BY 
            follower_count.count DESC
        LIMIT ?
        SQL
        results.map { |result| Question.new(result)}
    end


    attr_accessor :id, :question_id, :follower_id

    def initialize(hash)
        @question_id = hash['question_id']
        @follower_id = hash['follower_id']
    end

    


end