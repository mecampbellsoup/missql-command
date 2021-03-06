class Level < ActiveRecord::Base
  has_many :user_databases
  has_many :level_pages, :dependent => :destroy
  has_many :level_tests, :dependent => :destroy
  has_many :level_schemas, :dependent => :destroy

  before_create :load_dump

  def load_dump
    self.dump = File.open(self.database_path) do |file|
      file.read
    end
    if !self.dump
      self.errors.add(:dump, "Could not load dump file")
    end
  end

  def self.load_from_yaml(path)
    config = YAML.load_file(path)
    new_level = Level.create(config["level"])

    config["level_pages"].each do |page|
      new_level.level_pages << LevelPage.new(page)
    end

    if config["level_tests"]
      config["level_tests"].each do |test|
        new_level.level_tests << LevelTest.new(test)
      end
    end
    if config["level_schemas"]
      config["level_schemas"].each do |schema|
        new_schema = new_level.level_schemas.create(:table_name=> schema["table_name"])
          schema["schema_columns"].each do |column|
            new_schema.schema_columns << SchemaColumn.new(column)
          end
      end
    end
  end

  def correct_answer?(result)
    self.answer == result.to_a.to_s
  end

  def ordered_pages
    self.level_pages.order(:page_number)
  end

  def prev_level
    Level.find_by(:stage_number => (self.stage_number-1))
  end

  def next_level
    Level.find_by(:stage_number => (self.stage_number+1))
  end

end
