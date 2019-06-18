class Workout
  # ==================================================
  #                      SET UP
  # ==================================================
  # add attribute readers for instance accesss
  attr_reader :id, :name, :rx, :hero_wod

  # connect to heroku database
  if(ENV['DATABASE_URL'])
       uri = URI.parse(ENV['DATABASE_URL'])
       DB = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
   else
  # connect to postgres
  DB = PG.connect({:host => "localhost", :port => 5432, :dbname => 'WODL-api_development'})
  end
  
  # initialize options hash
  def initialize(opts = {}, id = nil)
    @id = id.to_i
    @name = opts["name"]
    @rounds = opts["rounds"]
    @reps = opts["reps"]
    @weight = opts["weight"]
    @time = opts["time"]
    @date = opts["date"]
    @comments = opts["comments"]
    @rx = opts["rx"]
    @hero_wod = opts["hero_wod"]
  end

  # ==================================================
  #                 PREPARED STATEMENTS
  # ==================================================
  # find workout
  DB.prepare("find_workout",
    <<-SQL
      SELECT workouts.*
      FROM workouts
      WHERE workouts.id = $1;
    SQL
  )

  # create workout
  DB.prepare("create_workout",
    <<-SQL
      INSERT INTO workouts (name, rounds, reps, weight, time, date, comments, rx, hero_wod)
      VALUES ( $1, $2, $3, $4, $5, $6, $7, $8, $9 )
      RETURNING id, name, rounds, reps, weight, time, date, comments, rx, hero_wod;
    SQL
  )

  # delete workout
  DB.prepare("delete_workout",
    <<-SQL
      DELETE FROM workouts
      WHERE id=$1
      RETURNING id;
    SQL
  )

  # update workout
  DB.prepare("update_workout",
    <<-SQL
      UPDATE workouts
      SET name = $2, rounds = $3, reps = $4, weight = $5, time = $6, date = $7, comments = $8, rx = $9, hero_wod = $10
      WHERE id = $1
      RETURNING id, name, rounds, reps, weight, time, date, comments, rx, hero_wod;
    SQL
  )

  # ==================================================
  #                      ROUTES
  # ==================================================
  # get all
  def self.all
    results = DB.exec("SELECT * FROM workouts;")
    return results.map do |result|
      # turn completed value into boolean
      if result["rx"] === 'f'
        result["rx"] = false
      else
        result["rx"] = true
      end
      if result["hero_wod"] === 'f'
        result["hero_wod"] = false
      else
        result["hero_wod"] = true
      end
      # create and return the tasks
      workout = Workout.new(result, result["id"])
    end
  end

  # get one by id
  def self.find(id)
    # find the result
    result = DB.exec_prepared("find_workout", [id]).first
    p result
    p '---'
    # turn completed value into boolean
    if result["rx"] === 'f'
      result["rx"] = false
    else
      result["rx"] = true
    end
    if result["hero_wod"] === 'f'
      result["hero_wod"] = false
    else
      result["hero_wod"] = true
    end
    p result
    # create and return the task
    workout = Workout.new(result, result["id"])
  end

  # create one
  def self.create(opts)
    # do not exist, default them to false
      if opts["rx"] === nil
        opts["rx"] = false
      end
      if opts["hero_wod"] === nil
        opts["hero_wod"] = false
      end
    # create workout
    results = DB.exec_prepared("create_workout", [opts["name"], opts["rounds"], opts["reps"], opts["weight"], opts["time"], opts["date"], opts["comments"], opts["rx"], opts["hero_wod"]])
    # turn completed value into boolean
    if results.first["rx"] === 'f'
      rx = false
    else
      rx = true
    end
    if results.first["hero_wod"] === 'f'
      hero_wod = false
    else
      hero_wod = true
    end
    # return
    workout = Workout.new(
      {
        "name" => results.first["name"],
        "rounds" => results.first["rounds"],
        "reps" => results.first["reps"],
        "weight" => results.first["weight"],
        "time" => results.first["time"],
        "date" => results.first["date"],
        "comments" => results.first["comments"],
        "rx" => rx,
        "hero_wod" => hero_wod
      },
      results.first["id"]
    )
  end

  # delete one
  def self.delete(id)
    # delete one
    results = DB.exec_prepared("delete_workout", [id])
    # if results.first exists, it successfully deleted
    if results.first
      return { deleted: true }
    else # otherwise it didn't, so leave a message that the delete was not successful
      return { message: "sorry cannot find workout at id: #{id}", status: 400}
    end
  end

  # update one
  def self.update(id, opts)
    # update
    results = DB.exec_prepared("update_workout", [id, opts["name"], opts["rounds"], opts["reps"], opts["weight"], opts["time"], opts["date"], opts["comments"], opts["rx"], opts["hero_wod"]])
    # if results.first exists, it was successfully updated so return it
    if results.first
      if results.first["rx"] === 'f'
        rx = false
      else
        rx = true
      end
      if results.first["hero_wod"] === 'f'
        hero_wod = false
      else
        hero_wod = true
      end
      # return
      workout = Workout.new(
        {
          "name" => results.first["name"],
          "rounds" => results.first["rounds"],
          "reps" => results.first["reps"],
          "weight" => results.first["weight"],
          "time" => results.first["time"],
          "date" => results.first["date"],
          "comments" => results.first["comments"],
          "rx" => rx,
          "hero_wod" => hero_wod
        },
        results.first["id"]
      )
    else # otherwise, alert that update failed
      return { message: "sorry, cannot find workout at id: #{id}", status: 400 }
    end
  end

end

# {
# 	"name": "thrusters, pull-ups, and 400m run",
# 	"rounds": "3",
# 	"reps": "30 thrusters, 30 pull-ups",
# 	"weight": "95lbs",
# 	"time": "22:23",
# 	"date": "6-14-19",
# 	"comments": "super-hot, couldn't breathe, hammy's sore from squats/row day before",
# 	"rx": "t",
# 	"hero_wod": false
# }
# {
#     "name": "Fran",
#     "rounds": "3",
#     "reps": "21-15-9",
#     "weight": "95lbs",
#     "time": "4:13",
#     "date": "6-15-19",
#     "comments": "super-hot and no breakfast, ripped R hand",
#     "rx": true,
#     "hero_wod": true
# }
