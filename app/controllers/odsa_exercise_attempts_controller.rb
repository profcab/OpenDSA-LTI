class OdsaExerciseAttemptsController < ApplicationController
  # load_and_authorize_resource

  #~ Action methods ...........................................................

  # -------------------------------------------------------------
  # POST /odsa_exercise_attempts
  def create
    inst_book = InstBook.find_by(id: params[:inst_book_id])
    inst_section = InstSection.find_by(id: params[:inst_section_id])
    inst_exercise = InstExercise.find_by(short_name: params[:sha1])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                  params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first

    unless exercise_progress = OdsaExerciseProgress.where("user_id=? and inst_book_section_exercise_id=?",
                                                 current_user.id,
                                                 inst_book_section_exercise.id).first

      exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                    inst_book_section_exercise: inst_book_section_exercise)
      exercise_progress.save
    end

    question_name = params['problem_type']
    if params[:non_summative]
      question_name = params[:non_summative]
    end
    if params[:attempt_content] == "hint"
      request_type = "hint"
    else
      request_type = "attempt"
    end

    worth_credit = (params[:complete].to_i == 1 and params[:count_hints].to_i == 0 and params[:attempt_number].to_i == 1)

    if inst_exercise.short_name.include? "Summ"
      if (exercise_progress['hinted_exercise'].to_s == question_name.to_s)
        worth_credit = false
      end
    end

    exercise_attempt = OdsaExerciseAttempt.new(
                                              inst_book: inst_book,
                                              user: current_user,
                                              inst_section: inst_section,
                                              inst_book_section_exercise: inst_book_section_exercise,
                                              worth_credit: worth_credit,
                                              correct: params[:complete],
                                              time_done: Time.now,
                                              time_taken: params[:time_taken],
                                              count_hints: params[:count_hints],
                                              count_attempts: params[:attempt_number],
                                              hint_used: params[:count_hints].to_i > 0,
                                              question_name: question_name,
                                              request_type: request_type ,
                                              ip_address: request.ip)

    respond_to do |format|
      if exercise_attempt.save

        exercise_progress = OdsaExerciseProgress.where(
                                                  "user_id=? and inst_book_section_exercise_id=?",
                                                  current_user.id,
                                                  inst_book_section_exercise.id).first


        format.json  { render :json => {
                                        :exercise_progress => exercise_progress,
                                        :threshold => inst_book_section_exercise.threshold}}
      else
        msg = { :status => "fail", :message => "Fail!" }
        format.json  { render :json => msg }
      end
    end
  end

  # -------------------------------------------------------------
  # POST /odsa_exercise_attempts/pe
  def create_pe
    inst_book = InstBook.find_by(id: params[:inst_book_id])
    inst_section = InstSection.find_by(id: params[:inst_section_id])
    inst_exercise = InstExercise.find_by(short_name: params[:exercise])
    inst_book_section_exercise = InstBookSectionExercise.where(
                                  "inst_book_id=? and inst_section_id=? and inst_exercise_id=?",
                                  params[:inst_book_id], params[:inst_section_id], inst_exercise.id).first

    if inst_book_section_exercise != nil
      unless exercise_progress = OdsaExerciseProgress.where("user_id=? and
                                                   inst_book_section_exercise_id=?",
                                                   current_user.id,
                                                   inst_book_section_exercise.id).first

        exercise_progress = OdsaExerciseProgress.new(user: current_user,
                                                      inst_book_section_exercise: inst_book_section_exercise)
        exercise_progress.save
      end

      correct = params[:score].to_f >= params[:threshold].to_f

      exercise_attempt = OdsaExerciseAttempt.new(
                                                inst_book: inst_book,
                                                user: current_user,
                                                inst_section: inst_section,
                                                inst_book_section_exercise: inst_book_section_exercise,
                                                worth_credit: correct,
                                                correct: correct,
                                                time_done: Time.now,
                                                time_taken: (params[:total_time].to_f/1000).round,
                                                count_hints: 0,
                                                count_attempts: params[:uiid],
                                                hint_used: 0,
                                                question_name: params[:exercise],
                                                request_type: "PE" ,
                                                ip_address: request.ip,
                                                pe_score: params[:score],
                                                pe_steps_fixed: params[:steps_fixed])

      respond_to do |format|
        if exercise_attempt.save
          exercise_progress = OdsaExerciseProgress.where(
                                                    "user_id=? and inst_book_section_exercise_id=?",
                                                    current_user.id,
                                                    inst_book_section_exercise.id).first
          format.json  { render :json => {
                                          :exercise_progress => exercise_progress,
                                          :threshold => inst_book_section_exercise.threshold}}
        else
          msg = { :status => "fail", :message => "Fail!" }
          format.json  { render :json => msg }
        end
      end
    else
      respond_to do |format|
        msg = { :status => "fail", :message => "Fail!" }
        format.json  { render :json => msg }
      end
    end
  end

  def get_count
    practiced_ex = OdsaExerciseAttempt.count(:conditions => "request_type <> 'hint'") + CodeWorkout::EXERCISES_SOLVED

    respond_to do |format|
      format.json  { render :json => {:practiced_ex => practiced_ex}}
    end
  end

  #~ Private instance methods .................................................
end
