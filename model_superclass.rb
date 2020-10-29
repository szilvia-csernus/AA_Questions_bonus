require 'active_support/inflector'
require_relative 'questions_db'

class ModelSuperclass
    
    def self.table
        self.name.tableize
    end

    def self.map_results(results)
        results.map { |data| self.new(data)}
    end
    
    def self.all
        results = QuestionsDatabase.instance.execute("SELECT * FROM #{table}")
        map_results(results)
    end

    def self.find_by_id(id)
        results = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT 
            * 
        FROM 
            #{table}
        WHERE
            id = ?
        SQL
        map_results(results)[0]
    end

    def self.where(constraint)

        if constraint.is_a?(Hash)
            sql_where = constraint.keys.map { |key| "#{key} = ?"}.join(" AND ")
            values = constraint.values
        else
            sql_where = constraint
            values = []
        end
        
        results = QuestionsDatabase.instance.execute(<<-SQL, *values)
        SELECT 
            * 
        FROM 
            #{table}
        WHERE
            #{sql_where}
        SQL
        
        map_results(results)
    end

    def self.find_by(constraint)
        self.where(constraint)
    end

    def map_table_data
        table_data = instance_variables.map do |var|
            [var.to_s[1..-1], instance_variable_get(var)]
        end
        Hash[table_data]
    end

    def save
        self.id.nil? ? create : update
    end

    def create

        table_data = map_table_data
        table_data.delete("id")
        columns = table_data.keys
        
        col_names = columns.join(", ")
        question_marks = (["?"] * table_data.count).join(", ")
        values = table_data.values

        QuestionsDatabase.instance.execute(<<-SQL, *values)
        INSERT INTO
            #{self.class.table} (#{col_names})
        VALUES
            (#{question_marks})
        SQL

        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update

        table_data = map_table_data
        columns = table_data.keys
        columns.delete("id")
        sql_set = table_data.keys.map { |col| "#{col} = ?" }.join(", ")
        values = table_data.values

        QuestionsDatabase.instance.execute(<<-SQL, *values, id)
        UPDATE
            #{self.class.table}
        SET
            #{sql_set}
        WHERE
            id = ?
        SQL
    end
end
