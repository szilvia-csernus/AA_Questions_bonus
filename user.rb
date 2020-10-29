require_relative "questions_db"
require_relative "model_superclass"
require_relative "question_follow"
require_relative "question_like"
require_relative "reply"
require_relative "question"

class User < ModelSuperclass

    def self.find_by_name(first_name, last_name)
        results = QuestionsDatabase.instance.execute(<<-SQL, first_name, last_name)
        SELECT 
            * 
        FROM 
            users
        WHERE
            fname = ? AND lname = ?
        SQL
        results.map { |result| User.new(result)}
    end

    attr_accessor :id, :fname, :lname

    def initialize(hash = {})
        @id = hash['id']
        @fname = hash['fname']
        @lname = hash['lname']
    end

    def authored_questions
        Question.find_by_author_id(@id)
    end

    def authored_replies
        Reply.find_by_user_id(@id)
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(@id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_liker_id(@id)
    end

    def average_karma
        results = QuestionsDatabase.instance.execute(<<-SQL, @id)
        
        SELECT
            CAST((COALESCE(SUM(like_counts_per_questions.count), 0) / 
            COALESCE(COUNT(like_counts_per_questions.question_id), 1)) AS FLOAT)
            AS avg
        FROM
            (SELECT 
                question_id, COUNT(question_likes.liker_id) AS count
            FROM 
                question_likes
            INNER JOIN
                (SELECT 
                    id 
                FROM 
                    questions
                WHERE
                    author_id = ?
                ) authored_questions
            GROUP BY
                question_id
            ) like_counts_per_questions     
        SQL
        results[0]["avg"]
        
    end

end