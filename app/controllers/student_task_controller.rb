class StudentTaskController < ApplicationController
  helper :submitted_content

  def action_allowed?
    ['Instructor', 'Teaching Assistant', 'Administrator', 'Super-Administrator', 'Student'].include? current_role_name
  end

  def impersonating_as_admin?
    original_user = session[:original_user]
    admin_role_ids = Role.where(name:['Administrator','Super-Administrator']).pluck(:id)
    admin_role_ids.include? original_user.role_id
  end

  def impersonating_as_ta?
    original_user = session[:original_user]
    ta_role = Role.where(name:['Teaching Assistant']).pluck(:id)
    ta_role.include? original_user.role_id
  end

  def list
    redirect_to(controller: 'eula', action: 'display') if current_user.is_new_user
    session[:user] = User.find_by(id: current_user.id)
    @student_tasks = StudentTask.from_user current_user
    if session[:impersonate] && !impersonating_as_admin?

      if impersonating_as_ta?
        ta_course_ids = TaMapping.where(:ta_id => session[:original_user].id).pluck(:course_id)
        @student_tasks = @student_tasks.select {|t| ta_course_ids.include?t.assignment.course_id }
      else
        @student_tasks = @student_tasks.select {|t| session[:original_user].id == t.assignment.course.instructor_id }
      end
    end
    @student_tasks.select! {|t| t.assignment.availability_flag }

    # #######Tasks and Notifications##################
    @tasknotstarted = @student_tasks.select(&:not_started?)
    @taskrevisions = @student_tasks.select(&:revision?)

    ######## Students Teamed With###################
    @students_teamed_with = StudentTask.teamed_students(current_user, session[:ip])
  end

  def view
    StudentTask.from_participant_id params[:id]
    @participant = AssignmentParticipant.find(params[:id])
    @can_submit = @participant.can_submit
    @can_review = @participant.can_review
    @can_take_quiz = @participant.can_take_quiz
    @authorization = Participant.get_authorization(@can_submit, @can_review, @can_take_quiz)
    @team = @participant.team
    denied unless current_user_id?(@participant.user_id)
    @assignment = @participant.assignment
    @can_provide_suggestions = @assignment.allow_suggestions
    @topic_id = SignedUpTeam.topic_id(@assignment.id, @participant.user_id)
    @topics = SignUpTopic.where(assignment_id: @assignment.id)
    # Timeline feature
    @timeline_list = StudentTask.get_timeline_data(@assignment, @participant, @team)
    
    #THE FOLLOWING CODE IS ADDED FOR THE TAG COUNT FEATURE
    questionnaires = @assignment.questionnaires
    @total_tags = 0
    @completed_tags = 0
    questionnaires.each do |questionnaire|
      if questionnaire.type == "ReviewQuestionnaire"
        deployments = TagPromptDeployment.where(questionnaire: questionnaire)
        deployments = deployments.select {|tag| tag.tag_prompt.control_type.downcase != "checkbox"}
        reviews = if @assignment.varying_rubrics_by_round?
                    ReviewResponseMap.get_responses_for_team_round(@participant.team, @round)
                  else
                    ReviewResponseMap.get_assessments_for(@participant.team)
                  end
        answers = []
        reviews.each {|response| answers += Answer.where(response: response)}
        answers.each do |answer|
          if answer.comments.nil? or answer.comments ==""
            tags = deployments.find_all {|tag| tag.question_type == answer.question.type}
            @total_tags += tags.count
          end
        end
        deployments.each do |deployment|
          @completed_tags += AnswerTag.where("tag_prompt_deployment_id = ? AND user_id = ? AND value != ?",
                         deployment, @participant.user_id, 0).count
        end
      end
    end
  end

  def others_work
    @participant = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@participant.user_id)

    @assignment = @participant.assignment
    # Finding the current phase that we are in
    due_dates = AssignmentDueDate.where(parent_id: @assignment.id)
    @very_last_due_date = AssignmentDueDate.where(parent_id: @assignment.id).order("due_at DESC").limit(1)
    next_due_date = @very_last_due_date[0]
    for due_date in due_dates
      if due_date.due_at > Time.now
        next_due_date = due_date if due_date.due_at < next_due_date.due_at
      end
    end

    @review_phase = next_due_date.deadline_type_id
    if next_due_date.review_of_review_allowed_id == DeadlineRight::LATE or next_due_date.review_of_review_allowed_id == DeadlineRight::OK
      @can_view_metareview = true if @review_phase == DeadlineType.find_by(name: "metareview").id
    end

    @review_mappings = ResponseMap.where(reviewer_id: @participant.id)
    @review_of_review_mappings = MetareviewResponseMap.where(reviewer_id: @participant.id)
  end

  def your_work; end
end
