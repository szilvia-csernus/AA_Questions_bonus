require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')

        self.results_as_hash = true
        self.type_translation = true
    end
end

class User

    def self.all
        results = QuestionsDatabase.instance.execute('SELECT * FROM users')
        results.map { |result| User.new(result)}
    end

    def self.find_by_id(user_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT 
            * 
        FROM 
            users
        WHERE
            id = ?
        SQL
        results.map { |result| User.new(result)}
    end

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

    def save
        self.id.nil? ? create : update
    end

    def create

        QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
            INSERT INTO
                users (fname, lname)
            VALUES
                (?, ?)
        SQL

        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update

        QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
            UPDATE
                users
            SET
                fname = ?, lname = ?
            WHERE
                id = ?
        SQL

    end

end

class Question

    def self.all
        results = QuestionsDatabase.instance.execute('SELECT * FROM questions')
        results.map { |result| Question.new(result)}
    end

    def self.find_by_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            questions
        WHERE
            id = ?
        SQL
        results.map { |result| Question.new(result)}
    end

    def self.find_by_author_id(author_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, author_id)
        SELECT 
            * 
        FROM 
            questions
        WHERE
            author_id = ?
        SQL
        results.map { |result| Question.new(result)}
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    attr_accessor :id, :title, :body, :author_id

    def initialize(hash = {})
        @id = hash['id']
        @title = hash['title']
        @body = hash['body']
        @author_id = hash['author_id']
    end

    def author
        User.find_by_id(@author_id)
    end

    def replies
        Reply.find_by_question_id(@id)
    end

    def followers
        QuestionFollow.followers_for_question_id(@id)
    end

    def likers
        QuestionLike.likers_for_question_id(@id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(@id)
    end

    def save
        self.id.nil? ? create : update
    end

    def create

        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
            INSERT INTO
                questions (title, body, author_id)
            VALUES
                (?, ?, ?)
        SQL

        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update

        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
            UPDATE
                questions
            SET
                title = ?, body = ?, author_id = ?
            WHERE
                id = ?
        SQL

    end

end

class QuestionFollow

    def self.all
        results = QuestionsDatabase.instance.execute('SELECT * FROM question_follows')
        results.map { |result| QuestionFollow.new(result)}
    end

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

class Reply

    def self.all
        results = QuestionsDatabase.instance.execute('SELECT * FROM replies')
        results.map { |result| Reply.new(result)}
    end

    def self.find_by_id(reply_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, reply_id)
        SELECT 
            * 
        FROM 
            replies
        WHERE
            id = ?
        SQL
        results.map { |result| Reply.new(result)}
    end

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

    def save
        self.id.nil? ? create : update
    end

    def create

        QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_reply, @user_id, @body)
            INSERT INTO
                replies (question_id, parent_reply, user_id, body)
            VALUES
                (?, ?, ?, ?)
        SQL

        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update

        QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_reply, @user_id, @body, @id)
            UPDATE
                replies 
            SET
                question_id = ?, parent_reply = ?, user_id = ?, body = ?
            WHERE
                id = ?
        SQL

    end

end

class QuestionLike

    def self.all
        results = QuestionsDatabase.instance.execute('SELECT * FROM question_likes')
        results.map { |result| QuestionLike.new(result)}
    end

    def self.find_by_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            question_likes
        WHERE
            question_id = ?
        SQL
        results.map { |result| QuestionLike.new(result)}
    end

    def self.liked_questions_for_liker_id(liker_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, liker_id)
        SELECT
            *
        FROM
            questions
        JOIN    
            (SELECT 
                question_id
            FROM 
                question_likes
            WHERE
                liker_id = ?
            ) liked_questions
        ON questions.id = liked_questions.question_id

        SQL
        results.map { |result| Question.new(result)}
    end

    def self.likers_for_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            users
        JOIN
            question_likes
        ON users.id = liker_id
        WHERE
            question_likes.question_id = ?
        SQL
        results.map { |result| User.new(result)}
    end

    def self.num_likes_for_question_id(question_id)
        results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            COUNT(question_likes.liker_id)
        FROM 
            question_likes
        WHERE
            question_id = ?
        SQL
        results[0]["COUNT(question_likes.liker_id)"]
    end

    def self.most_liked_questions(n)
        results = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            *
        FROM
            questions
        JOIN
            (SELECT 
                questions.id, COUNT(question_likes.liker_id) AS count
            FROM 
                questions
            JOIN
                question_likes 
                ON question_likes.question_id = questions.id
            GROUP BY questions.id

            ) liker_count
        ON questions.id = liker_count.id
        ORDER BY 
            liker_count.count DESC
        LIMIT ?
        SQL
        results.map { |result| Question.new(result)}
    end

    attr_accessor :id, :question_id, :liker_id

    def initialize(hash)
        @question_id = hash['question_id']
        @liker_id = hash['liker_id']
    end

end