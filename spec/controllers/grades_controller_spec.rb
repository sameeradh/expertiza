describe GradesController do
  let(:review_response) { build(:response) }
  let(:assignment) { build(:assignment, id: 1, questionnaires: [review_questionnaire], is_penalty_calculated: true) }
  let(:assignment_questionnaire) { build(:assignment_questionnaire, used_in_round: 1, assignment: assignment) }
  let(:participant) { build(:participant, id: 1, assignment: assignment, user_id: 1) }
  let(:participant2) { build(:participant, id: 2, assignment: assignment, user_id: 1) }
  let(:review_questionnaire) { build(:questionnaire, id: 1, questions: [question]) }
  let(:admin) { build(:admin) }
  let(:instructor) { build(:instructor, id: 6) }
  let(:question) { build(:question) }
  let(:team) { build(:assignment_team, id: 1, assignment: assignment, users: [instructor]) }
  let(:student) { build(:student) }
  let(:assignment_due_date) { build(:assignment_due_date) }
  let(:participantOurs) { Participant.new( id: 37619, can_submit: true, can_review: true, user_id: 7552, parent_id: 876,
                                submitted_at: nil, permission_granted: nil, penalty_accumulated: 0, grade: nil,
                                type: "AssignmentParticipant", handle: "handle", time_stamp: nil, digital_signature: nil,
                                duty: nil, can_take_quiz: true, Hamer: 1.0, Lauw: 0.0)
                       }
  let(:reviewer) { build(:participant, id: 2, assignment: assignment, user_id: 2) }
  let(:review_response_map) { build(:review_response_map, id: 1) }

  #Multiple questions for proper testing of tags
  let(:question1) { build(:question, id: 1, type: "normal") }
  let(:question2) { build(:question, id: 2, type: "normal") }
  let(:answer1) { build(:answer, id: 1, question_id: 1)}
  let(:answer2) { build(:answer, id: 2, question_id: 2)}

  #Added for E1953
  #These are tag prompts for quesitons
  let(:tag_prompt1) {TagPrompt.new(id: 1, prompt: "Good?", control_type: "slider")}
  let(:tag_prompt2) {TagPrompt.new(id: 2, prompt: "Bad?", control_type: "slider")}
  let(:tag_prompt3) {TagPrompt.new(id: 3, prompt: "Okay?", control_type: "slider")}
  let(:tag_prompt4) {TagPrompt.new(id: 4, prompt: "Very Bad?", control_type: "checkbox")}

  #The maps from tag prompts to questionnaires
  let(:deployment1) {TagPromptDeployment.new(id: 1, tag_prompt: tag_prompt1, assignment: assignment,
                                             questionnaire: review_questionnaire, question_type: "normal")}
  let(:deployment2) { TagPromptDeployment.new(id: 2, tag_prompt: tag_prompt2, assignment: assignment,
                                              questionnaire: review_questionnaire, question_type: "normal")}
  let(:deployment3) { TagPromptDeployment.new(id: 3, tag_prompt: tag_prompt3, assignment: assignment,
                                              questionnaire: review_questionnaire, question_type: "normal")}
  let(:deployment4) { TagPromptDeployment.new(id: 4, tag_prompt: tag_prompt4, assignment: assignment,
                                              questionnaire: review_questionnaire, question_type: "normal")}



  #@participant = AssignmentParticipant.find(params[:id])
  #@assignment = @participant.assignment
  #@team = @participant.team
  #@team_id = @team.id
  #questionnaires = @assignment.questionnaires
  #@questions = retrieve_questions questionnaires, @assignment.id
  #@pscore = @participant.scores(@questions)
  #@vmlist = []
  #@total_tags_array =[]
  #@completed_tags_array =[]

  # Test for the page grades/view_team? displays the fraction of review comments to tag over the
  # total available review comments possible to tag.
  #This method so far, only tests functionality added in E1953
  describe '#view_team' do
    before(:each) do
      #Login as a user
      stub_current_user(instructor, instructor.role.name, instructor.role)

      #allow(StudentTask).to receive(:from_participant_id).with("1").and_return(student_task)

      allow(AssignmentParticipant).to receive(:find).with("1").and_return(participant)
      allow(AssignmentParticipant).to receive(:find).with(1).and_return(participant)

      allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, questionnaire_id: 1).and_return([assignment_questionnaire])
      allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, used_in_round: 2).and_return([])
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 1).and_return(assignment_questionnaire)

      allow(Question).to receive(:find).with(1).and_return(question1)
      allow(Question).to receive(:find).with(2).and_return(question2)

      allow(Answer).to receive(:where).with(response_id: 1).and_return([answer1, answer2])

      allow(question1).to receive(:questionnaire).and_return(review_questionnaire)
      allow(question2).to receive(:questionnaire).and_return(review_questionnaire)

      allow(assignment).to receive(:questionnaires).and_return([review_questionnaire])
      allow(assignment).to receive(:varying_rubrics_by_round?).and_return(false)

      allow(participant).to receive(:team).and_return(team)

      allow(team).to receive(:participants).and_return([participant])

      allow(review_questionnaire).to receive(:used_in_round).and_return(0)
      allow(review_questionnaire).to receive(:questions).and_return([question1, question2])

      allow(TagPrompt).to receive(:find).with(1).and_return(tag_prompt1)
      allow(TagPrompt).to receive(:find).with(2).and_return(tag_prompt2)
      allow(TagPrompt).to receive(:find).with(3).and_return(tag_prompt3)
      allow(TagPrompt).to receive(:find).with(4).and_return(tag_prompt4)

      allow(TagPromptDeployment).to receive(:where).with(questionnaire_id: 1, assignment_id: 1).and_return([deployment1, deployment2, deployment3, deployment4])

      allow(deployment1).to receive(:answer_length_threshold).and_return(0)
      allow(deployment2).to receive(:answer_length_threshold).and_return(0)
      allow(deployment3).to receive(:answer_length_threshold).and_return(0)
      allow(deployment4).to receive(:answer_length_threshold).and_return(0)

      allow(ReviewResponseMap).to receive(:get_assessments_for).with(team).and_return([review_response_map])

      allow(review_response_map).to receive(:response_id).and_return(1)
    end
    context 'when user clicks on assignment to view' do
      it "reports zero completed tags correctly" do
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment1, user_id: 1, answer: answer2).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment2, user_id: 1, answer: answer2).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment3, user_id: 1, answer: answer2).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment4, user_id: 1, answer: answer2).and_return([])

        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment1, user_id: 1, answer: answer1).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment2, user_id: 1, answer: answer1).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment3, user_id: 1, answer: answer1).and_return([])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment4, user_id: 1, answer: answer1).and_return([])
        params = {id: 1}
        get :view_team, params
        expect(controller.instance_variable_get(:@participant)).to eq(participant)
        expect(assigns(:completed_tags)).to eq(0)
        expect(assigns(:total_tags)).to eq(6)
        end
    end
    it "reports some completed tags correctly" do
        answer_tags = [AnswerTag.new(value: 0), AnswerTag.new(value: 1), AnswerTag.new(value: -1), AnswerTag.new(value: 1),
                       AnswerTag.new(value: 1), AnswerTag.new(value: 1), AnswerTag.new(value: -1), AnswerTag.new(value: 0),]
        
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment1, user_id: 1, answer: answer2).and_return([answer_tags[0]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment2, user_id: 1, answer: answer2).and_return([answer_tags[1]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment3, user_id: 1, answer: answer2).and_return([answer_tags[2]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment4, user_id: 1, answer: answer2).and_return([answer_tags[3]])
        
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment1, user_id: 1, answer: answer1).and_return([answer_tags[4]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment2, user_id: 1, answer: answer1).and_return([answer_tags[5]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment3, user_id: 1, answer: answer1).and_return([answer_tags[6]])
        allow(AnswerTag).to receive(:where).with(tag_prompt_deployment_id: deployment4, user_id: 1, answer: answer1).and_return([answer_tags[7]])
        params = {id: 1}
        get :view_team, params
        expect(controller.instance_variable_get(:@participant)).to eq(participant)
        expect(assigns(:completed_tags)).to eq(5)
        expect(assigns(:total_tags)).to eq(6)
      end
  end

  #describe '#view_team' do
  #  context 'grades#view_team Student looks at an assignment with review comments to tag' do
      #it 'displays the correct number of review comments to tag and total review comments' do
       # allow(Participant).to receive(:where).with(parent_id: 1).and_return([participant])
        #allow(Assignment).to receive(:find).with('1').and_return(assignment)
        #allow(TeamsUser).to receive(:where).with(user_id: 1).and_return([double('TeamsUser', team_id: 1)])
        #team.users = []
        #allow(Team).to receive(:find).with(1).and_return(team)
        #allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, used_in_round: 2).and_return([])
        #@vmlist = []
        #@total_tags_array =[]
        #@completed_tags_array =[]
        #counter_for_same_rubric = 0
        # allow(Assignment).to receive(:find).with('1').and_return(assignment)
        #expect(participantOurs.user_id).to eq(7552)
        #get :view_team, params
        #expect(response).to render_template(:view_team)
      #end
    #end
  #end
  #let(:round) {build(:questionnaire)}
  #let(:vm) {build(:assignment_questionnaire, :assignment, )}
  #vm = VmQuestionResponse.new(questionnaire, @assignment, @round)
  #vmquestions = questionnaire.questions
  #vm.add_questions(vmquestions)
  #vm.add_team_members(@team)
  #vm.add_reviews(@participant, @team, @assignment.varying_rubrics_by_round?)
  #vm.number_of_comments_greater_than_10_words
  #let( :vmlist ) {:assignment_questionnaire}
  #let(:round) {used}

  before(:each) do
    allow(AssignmentParticipant).to receive(:find).with('1').and_return(participant)
    allow(participant).to receive(:team).and_return(team)
    stub_current_user(instructor, instructor.role.name, instructor.role)
    allow(Assignment).to receive(:find).with('1').and_return(assignment)
    allow(Assignment).to receive(:find).with(1).and_return(assignment)
  end

  describe '#view' do
    before(:each) do
      allow(Answer).to receive(:compute_scores).with([review_response], [question]).and_return(max: 95, min: 88, avg: 90)
      allow(Participant).to receive(:where).with(parent_id: 1).and_return([participant])
      allow(AssignmentParticipant).to receive(:find).with(1).and_return(participant)
      allow(assignment).to receive(:late_policy_id).and_return(false)
      allow(assignment).to receive(:calculate_penalty).and_return(false)
    end

    context 'when current assignment varys rubric by round' do
      it 'retrieves questions, calculates scores and renders grades#view page' do
        allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, used_in_round: 2).and_return([assignment_questionnaire])
        allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, questionnaire_id: 1).and_return([assignment_questionnaire])
        params = {id: 1}
        get :view, params
        expect(controller.instance_variable_get(:@questions)[:review1].size).to eq(1)
        expect(response).to render_template(:view)
      end
    end

    context 'when current assignment does not vary rubric by round' do
      it 'calculates scores and renders grades#view page' do
        allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, used_in_round: 2).and_return([])
        allow(ReviewResponseMap).to receive(:get_assessments_for).with(team).and_return([review_response])
        params = {id: 1}
        get :view, params
        expect(controller.instance_variable_get(:@questions)[:review].size).to eq(1)
        expect(response).to render_template(:view)
      end
    end
  end

  describe '#view_my_scores' do
    before(:each) do
      allow(Participant).to receive(:find_by).with(id: '1').and_return(participant)
      allow(Participant).to receive(:find).with('1').and_return(participant)
    end

    context 'when view_my_scores page is not allow to access' do
      it 'shows a flash errot message and redirects to root path (/)' do
        allow(TeamsUser).to receive(:where).with(user_id: 1).and_return([double('TeamsUser', team_id: 1)])
        team.users = []
        allow(Team).to receive(:find).with(1).and_return(team)
        params = {id: 1}
        get :view_my_scores, params
        expect(response).to redirect_to('/')
      end
    end

    context 'when view_my_scores page is allow to access' do
      it 'renders grades#view_my_scores page' do
        allow(TeamsUser).to receive(:where).with(any_args).and_return([double('TeamsUser', team_id: 1)])
        allow(Team).to receive(:find).with(1).and_return(team)
        allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 1).and_return(assignment_questionnaire)
        allow(AssignmentQuestionnaire).to receive(:where).with(any_args).and_return([assignment_questionnaire])
        allow(review_questionnaire).to receive(:get_assessments_round_for).with(participant, 1).and_return([review_response])
        allow(Answer).to receive(:compute_scores).with([review_response], [question]).and_return(max: 95, min: 88, avg: 90)
        allow(Participant).to receive(:where).with(parent_id: 1).and_return([participant])
        allow(AssignmentParticipant).to receive(:find).with(1).and_return(participant)
        allow(assignment).to receive(:late_policy_id).and_return(false)
        allow(assignment).to receive(:calculate_penalty).and_return(false)
        allow(assignment).to receive(:compute_total_score).with(any_args).and_return(100)
        params = {id: 1}
        session = {user: instructor}
        get :view_my_scores, params, session
        expect(response).to render_template(:view_my_scores)
      end
    end


  end

  xdescribe '#view_team' do
    it 'renders grades#view_team page' do
      allow(participant).to receive(:team).and_return(team)
      params = {id: 1}
      get :view_team, params
      expect(response).to render_template(:view_team)
    end
  end

  describe '#edit' do
    it 'renders grades#edit page' do
      allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, used_in_round: 2).and_return([])
      assignment_questionnaire.used_in_round = nil
      allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 1).and_return(assignment_questionnaire)
      allow(review_questionnaire).to receive(:get_assessments_for).with(participant).and_return([review_response])
      allow(Answer).to receive(:compute_scores).with([review_response], [question]).and_return(max: 95, min: 88, avg: 90)
      allow(assignment).to receive(:compute_total_score).with(any_args).and_return(100)
      params = {id: 1}
      get :edit, params
      expect(response).to render_template(:edit)
    end
  end

  describe '#instructor_review' do
    context 'when review exists' do
      it 'redirects to response#edit page' do
        allow(AssignmentParticipant).to receive(:find_or_create_by).with(user_id: 6, parent_id: 1).and_return(participant)
        allow(participant).to receive(:new_record?).and_return(false)
        allow(ReviewResponseMap).to receive(:find_or_create_by).with(reviewee_id: 1, reviewer_id: 1, reviewed_object_id: 1).and_return(review_response_map)
        allow(review_response_map).to receive(:new_record?).and_return(false)
        allow(Response).to receive(:find_by).with(map_id: 1).and_return(review_response)
        params = {id: 1}
        session = {user: instructor}
        get :instructor_review, params, session
        expect(response).to redirect_to('/response/edit?return=instructor')
      end
    end

    context 'when review does not exist' do
      it 'redirects to response#new page' do
        allow(AssignmentParticipant).to receive(:find_or_create_by).with(user_id: 6, parent_id: 1).and_return(participant2)
        allow(participant2).to receive(:new_record?).and_return(false)
        allow(ReviewResponseMap).to receive(:find_or_create_by).with(reviewee_id: 1, reviewer_id: 2, reviewed_object_id: 1).and_return(review_response_map)
        allow(review_response_map).to receive(:new_record?).and_return(true)
        allow(Response).to receive(:find_by).with(map_id: 1).and_return(review_response)
        params = {id: 1}
        session = {user: instructor}
        get :instructor_review, params, session
        expect(response).to redirect_to('/response/new?id=1&return=instructor')
      end
    end
  end

  describe '#update' do
    before(:each) do
      allow(participant).to receive(:update_attribute).with(any_args).and_return(participant)
    end
    context 'when total is not equal to participant\'s grade' do
      it 'updates grades and redirects to grades#edit page' do
        params = {
          id: 1,
          total_score: 98,
          participant: {
            grade: 96
          }
        }
        post :update, params
        expect(flash[:note]).to eq("The computed score will be used for #{participant.user.name}.")
        expect(response).to redirect_to('/grades/1/edit')
      end
    end

    context 'when total is equal to participant\'s grade' do
      it 'redirects to grades#edit page' do
        params = {
          id: 1,
          total_score: 98,
          participant: {
            grade: 98
          }
        }
        post :update, params
        expect(flash[:note]).to eq("The computed score will be used for #{participant.user.name}.")
        expect(response).to redirect_to('/grades/1/edit')
      end
    end
  end

  describe '#save_grade_and_comment_for_submission' do
    it 'saves grade and comment for submission and refreshes the grades#view_team page' do
      allow(AssignmentParticipant).to receive(:find_by).with(id: '1').and_return(participant)
      allow(participant).to receive(:team).and_return(build(:assignment_team, id: 2, parent_id: 8))
      params = {
        participant_id: 1,
        grade_for_submission: 100,
        comment_for_submission: 'comment'
      }
      post :save_grade_and_comment_for_submission, params
      expect(flash[:error]).to be nil
      expect(response).to redirect_to('/grades/view_team?id=1')
    end
  end
end
