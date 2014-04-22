class JobsController < ApplicationController

  ***REMOVED*** GET /jobs
  ***REMOVED*** GET /jobs.xml

  include CASControllerIncludes
  include AttribsHelper

  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_category_name,
    :auto_complete_for_course_name, :auto_complete_for_proglang_name]
  auto_complete_for :category, :name
  auto_complete_for :course, :name
  auto_complete_for :proglang, :name

  ***REMOVED***CalNet / CAS Authentication
  ***REMOVED***before_filter CASClient::Frameworks::Rails::Filter
  before_filter :goto_home_unless_logged_in

  ***REMOVED*** Ensures that only logged-in users can create, edit, or delete jobs
  before_filter :rm_login_required ***REMOVED***, :except => [ :index, :show ]

  ***REMOVED*** Ensures that only the user who created a job -- and no other users -- can edit
  ***REMOVED*** or destroy it.
  before_filter :correct_user_access, :only => [ :edit, :update, :resend_activation_email,
                                                  :delete, :destroy ]

  ***REMOVED*** Ensures that other users can't view your job if your job is not yet active!
  before_filter :view_ok_for_unactivated_job, :only => [ :show, :apply ]

  ***REMOVED*** Prohibits a user from watching his/her own job
  before_filter :watch_apply_ok_for_job, :only => [ :watch ]

  protected
  def search_params_hash
    h = {}
    ***REMOVED*** booleans
    h[:include_ended] = params[:include_ended] if ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:include_ended]) ***REMOVED***unless params[param].nil?

    ***REMOVED*** strings, directly copy attribs
    [:query, :tags, :page, :per_page, :as, :compensation].each do |param|
      h[param] = params[param] unless params[param].blank?
    end

    ***REMOVED*** dept. 0 => all
    h[:post_status]     = params[:post_status]     if params[:post_status]
    h[:department] = params[:department] if params[:department].to_i > 0
    h[:faculty]    = params[:faculty]    if params[:faculty].to_i    > 0
    h
  end

  public

  def index ***REMOVED***list
    ***REMOVED*** strip out some weird args
    ***REMOVED*** may cause double-request but that's okay
    redirect_to(search_params_hash) and return if [:commit, :utf8].any? {|k| !params[k].nil?}

    ***REMOVED*** Advanced search
    query_parms = {}
    query_parms[:department_id] = params[:department].to_i if params[:department] && params[:department].to_i > 0
    query_parms[:faculty_id   ] = params[:faculty].to_i    if params[:faculty] && params[:faculty].to_i > 0
    query_parms[:include_ended] = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:include_ended])
    query_parms[:compensation ] = params[:compensation] if params[:compensation].present?
    query_parms[:tags         ] = params[:tags] if params[:tags].present?
    query_parms[:post_status  ] = params[:post_status] if params[:post_status].present? and params[:post_status]

    ***REMOVED*** will_paginate
    query_parms[:page         ] = params[:page]     || 1
    query_parms[:per_page     ] = params[:per_page] || 10

    @query = params[:query] || ''
    @jobs = Job.find_jobs(@query, query_parms)
    @faculty = Faculty.find_by_sql("SELECT DISTINCT faculties.id, faculties.name FROM 
               faculties INNER JOIN sponsorships ON
               sponsorships.faculty_id=faculties.id INNER JOIN jobs ON
               jobs.id=sponsorships.job_id
               AND (jobs.end_date >= now() OR jobs.end_date is NULL) ORDER BY name ASC")
    ***REMOVED*** Set some view props
    @department_id = params[:department]   ? params[:department].to_i : 0
    @faculty_id    = params[:faculty]      ? params[:faculty].to_i    : 0
    @compensation  = params[:compensation]
    @post_status   = params[:post_status]

    respond_to do |format|
      format.html { render :action => :index }
      format.xml { render :xml => @jobs }
    end
  end

  ***REMOVED*** GET /jobs/1
  ***REMOVED*** GET /jobs/1.xml
  def show
    @job = Job.find(params[:id])

    ***REMOVED*** update watch time so this job is now 'read'
    if @current_user.present? && (watch=Watch.find(:first, :conditions => {:user_id => @current_user.id, :job_id => @job.id}))
        watch.mark_read
    end

    respond_to do |format|
      format.html ***REMOVED*** show.html.erb
      format.xml  { render :xml => @job }
    end
  end

  ***REMOVED*** GET /jobs/new
  ***REMOVED*** GET /jobs/new.xml
  def new
    @job = Job.new
    @job.num_positions = 0

    @faculty = Faculty.order("name").all
    @current_owners = @job.owners.select{|i| i != @current_user}
    owners = @job.owners + [@job.user]
    @owners_list = User.all.select{|i| !(owners).include?(i)}.sort_by{|u| u.name}

  end

  ***REMOVED*** GET /jobs/1/edit
  def edit
    @job = Job.find(params[:id])
    @job.mend

    @faculty = Faculty.order("name").all
    @current_owners = @job.owners.select{|i| i != @current_user}
    owners = @job.owners + [@job.user]
    @owners_list = User.all.sort_by{|u| u.name}
    respond_to do |format|
        format.html
        format.xml
    end

  end

  def resend_activation_email
    @job = Job.find(params[:id])
    @job.resend_email(true)
    flash[:notice] = 'Thank you. The activation email for this listing has '
    flash[:notice] << 'been re-sent to its faculty sponsors.'

    respond_to do |format|
      format.html { redirect_to(@job) }
    end
  end

  ***REMOVED*** POST /jobs
  ***REMOVED*** POST /jobs.xml
  def create
    params[:job][:user] = @current_user

    process_form_params

    params[:job][:activation_code] = 0

    sponsor = Faculty.find(params[:faculty_id].to_i) rescue nil
    @job = Job.new(params[:job])
    @job.update_attribs(params)
    @job.num_positions ||= 0
    if params.has_key?(:add_owners) and params[:add_owners].to_i > 0
      @job.owners << User.find(params[:add_owners])
    end
    if params.has_key?(:add_contacts) and params[:add_contacts].to_i > 0
      @job.primary_contact_id = params[:add_contacts].to_i
    else
      @job.primary_contact_id = @current_user.id
    end
    @job.populate_tag_list

    respond_to do |format|
      if @job.valid?
        if sponsor
          @sponsorship = Sponsorship.find_or_create_by_faculty_id_and_job_id(sponsor.id, @job.id)
          @job.sponsorships << @sponsorship
        end
        
        @job.save()

        flash[:notice] = 'Thank your for submitting a listing. It should now be available for other people to browse.'
        format.html { redirect_to(@job) }
        format.xml  { render :xml => @job, :status => :created, :location => @job }
      else
        @faculty_id = params[:faculty_id]
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  ***REMOVED*** PUT /jobs/1
  ***REMOVED*** PUT /jobs/1.xml
  def update
    process_form_params

    @job = Job.find(params[:id])
    changed_sponsors = update_sponsorships and false ***REMOVED*** TODO: remove when :active is resolved
    @job.update_attribs(params)

    respond_to do |format|
      if @job.update_attributes(params[:job])
        if params.has_key?(:delete_owners) and params[:delete_owners].to_i >= 0
          @job.owners.delete(User.find(params[:delete_owners]))
        end
        if params.has_key?(:add_owners) and params[:add_owners].to_i > 0
          @job.owners << User.find(params[:add_owners])
        end
        if params.has_key?(:add_contacts) and params[:add_contacts].to_i > 0
          @job.primary_contact_id = params[:add_contacts].to_i
        else
          @job.primary_contact_id = @current_user.id
        end
        @job.populate_tag_list

        ***REMOVED*** If the faculty sponsor changed, require activation again.
        ***REMOVED*** (require the faculty to confirm again)
        if changed_sponsors
          @job.resend_email(true) ***REMOVED*** sends the email too
        end
        flash[:notice] = 'Listing was successfully updated.'
        if params[:open_ended_end_date] == "true"
          @job.end_date = nil
        end

        @job.save
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end


  ***REMOVED*** Just the page that asks for confirmation for deletion of the job.
  ***REMOVED*** The actual deletion is performed by the "destroy" action.
  def delete
    @job = Job.find(params[:id])

    respond_to do |format|
      format.html
      format.xml
    end
  end

  ***REMOVED*** DELETE /jobs/1
  ***REMOVED*** DELETE /jobs/1.xml
  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      flash[:notice] = "Listing deleted successfully."
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
    end
  end

  def activate
    ***REMOVED*** /jobs/activate/job_id?a=xxx
    @job = Job.find :first, conditions: { activation_code: params[:a] }

    unless @job
      flash[:error] = 'Unable to process activation request.'
      return redirect_to jobs_url
    end

    @job.populate_tag_list

    @job.skip_handlers = true

    unless @job.save
      flash[:error] = 'Unsuccessful activation. Please contact us if the problem persists.'
      return redirect_to(jobs_url)
    end

    @job.skip_handlers = false
    flash[:notice] = 'Listing activated successfully.  Your listing is now available to be viewed by other users.'
    redirect_to @job

  end

  def job_read_more
    job = Job.find(params[:id])
    render :text=> job.desc
  end

  def job_read_less
    job = Job.find(params[:id])
    desc = job.desc.first(100)
    desc = desc << "..." if job.desc.length > 100
    render :text=>  desc
  end

  def watch
    job = Job.find(params[:id])
    watch = Watch.new({:user=> @current_user, :job => job})

    respond_to do |format|
      if watch.save
        flash[:notice] = 'Job is now watched. You can find a list of your watched jobs on the dashboard.'
        format.html { redirect_to(job) } ***REMOVED***:controller=>:dashboard) }
      else
        flash[:notice] = 'Unsuccessful job watch. Perhaps you\'re already watching this job?'
        format.html { redirect_to(job) }
      end
    end
  end

 def unwatch
   job = Job.find(params[:id])
   watch = Watch.find(:first, :conditions=>{:user_id=> @current_user.id, :job_id => job.id})

   respond_to do |format|
     if watch.destroy
       flash[:notice] = 'Job is now unwatched. You can find a list of your watched jobs on the dashboard.'
       format.html { redirect_to(job) }
     else
       flash[:notice] = 'Unsuccessful job un-watch. Perhaps you\'re not watching this job yet?'
       format.html { redirect_to(job) }
     end
   end

  end



  protected
  ***REMOVED*** Preprocesses form data for direct input to Job.update
  def process_form_params
    ***REMOVED*** Handles the text_fields for categories, courses, and programming languages
    [:category, :course, :proglang].each do |k|
      params[:job]["***REMOVED***{k.to_s}_names".to_sym] = params[k][:name]
    end
    ***REMOVED*** Handle end date
    params[:job][:end_date] = nil if params[:job].delete(:open_ended_end_date)
  end


  ***REMOVED*** Saves sponsorship specified in the params page.
  ***REMOVED*** Returns true if sponsorships changed at all for this update,
  ***REMOVED***   and false if they did not.
  def update_sponsorships
    ***REMOVED*** Only one sponsor allowed - may change later
    if params[:faculty_id] != '-1'
      @job.sponsorships.delete_all
      @job.sponsorships.create(faculty_id: params[:faculty_id])
    end
    return @job.sponsorships

  end

***REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED***
***REMOVED***     FILTERS      ***REMOVED***
***REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED******REMOVED***

  private
  def correct_user_access
    if (Job.find(params[:id]) == nil || (!@current_user.admin? and @current_user != Job.find(params[:id]).user and !Job.find(params[:id]).owners.include?(@current_user)))
      flash[:error] = "You don't have permissions to edit or delete that listing."
      redirect_to :controller => 'dashboard', :action => :index
    end
  end

end
