# Rails Architecture Blueprint: Concerns, Services & Helpers

## Overview

This document provides a Standard Operating Procedure (SOP) for deciding when and how to use **Concerns**, **Services**, and **Helpers** in Rails applications. Following these guidelines ensures code is maintainable, testable, and follows SOLID principles.

---

## Quick Decision Tree

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    "Where should this code go?"                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │ Is it shared behavior across  │
                    │ multiple models/controllers?  │
                    └───────────────────────────────┘
                          │                 │
                         YES               NO
                          │                 │
                          ▼                 ▼
              ┌─────────────────┐   ┌───────────────────────────┐
              │    CONCERN      │   │ Is it a complex business  │
              │                 │   │ operation with multiple   │
              │ • Callbacks     │   │ steps or external deps?   │
              │ • Scopes        │   └───────────────────────────┘
              │ • Validations   │         │                 │
              │ • Shared methods│        YES               NO
              └─────────────────┘         │                 │
                                          ▼                 ▼
                              ┌─────────────────┐   ┌───────────────────────────┐
                              │    SERVICE      │   │ Is it for formatting or   │
                              │                 │   │ presenting data in views? │
                              │ • Business logic│   └───────────────────────────┘
                              │ • External APIs │         │                 │
                              │ • Complex ops   │        YES               NO
                              │ • Orchestration │         │                 │
                              └─────────────────┘         ▼                 ▼
                                                  ┌─────────────┐   ┌─────────────┐
                                                  │   HELPER    │   │ Keep in     │
                                                  │             │   │ Model or    │
                                                  │ • View logic│   │ Controller  │
                                                  │ • Formatting│   └─────────────┘
                                                  │ • HTML gen  │
                                                  └─────────────┘
```

---

## 1. Concerns

### What is a Concern?

A **Concern** is a Ruby module that uses `ActiveSupport::Concern` to encapsulate shared behavior that can be mixed into multiple classes (models or controllers).

### When to Create a Concern

| ✅ Create a Concern When                   | ❌ Don't Create a Concern When    |
| ------------------------------------------ | --------------------------------- |
| Same code appears in 2+ models/controllers | Logic is specific to one class    |
| Behavior is reusable and generic           | It's a complex multi-step process |
| Adding callbacks, scopes, or validations   | Logic involves external services  |
| Extracting cross-cutting concerns          | It's presentation/view logic      |

### Why Use Concerns?

1. **DRY (Don't Repeat Yourself)** - Eliminate code duplication
2. **Single Responsibility** - Each concern handles one aspect
3. **Composition over Inheritance** - Mix behaviors without deep hierarchies
4. **Testability** - Test shared behavior in isolation

### Concern Types

#### Model Concerns

**Location**: `app/models/concerns/`

**Use For**:

- Shared validations
- Shared scopes
- Shared callbacks
- Shared instance/class methods

**Example - Soft Delete (Discardable)**:

```ruby
# app/models/concerns/discardable.rb
module Discardable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(discarded_at: nil) }
    scope :discarded, -> { where.not(discarded_at: nil) }
  end

  def discard
    update(discarded_at: Time.current)
  end

  def undiscard
    update(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end
end

# Usage in models:
class Project < ApplicationRecord
  include Discardable
end

class Company < ApplicationRecord
  include Discardable
end
```

#### Controller Concerns

**Location**: `app/controllers/concerns/`

**Use For**:

- Shared authentication/authorization logic
- Shared response handling
- Shared audit logging
- Shared filtering/sorting logic

**Example - Auditable**:

```ruby
# app/controllers/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  private

  def audit_create(record, module_name:, summary: nil)
    log_audit(
      action: "create",
      module_name: module_name,
      auditable: record,
      summary: summary || "Created #{record.model_name.human.downcase}: #{record_display_name(record)}",
      data_after: record.attributes
    )
  end

  def audit_update(record, module_name:, summary: nil)
    data_before = record.attributes.dup
    result = yield

    if result
      log_audit(
        action: "update",
        module_name: module_name,
        auditable: record,
        summary: summary || "Updated #{record.model_name.human.downcase}: #{record_display_name(record)}",
        data_before: data_before,
        data_after: record.attributes
      )
    end

    result
  end

  def audit_delete(record, module_name:, summary: nil)
    log_audit(
      action: "delete",
      module_name: module_name,
      auditable: record,
      summary: summary || "Deleted #{record.model_name.human.downcase}: #{record_display_name(record)}",
      data_before: record.attributes
    )
  end

  def record_display_name(record)
    record.respond_to?(:name) ? record.name : "##{record.id}"
  end
end

# Usage in controllers:
class ProjectsController < ApplicationController
  include Auditable

  def create
    @project = Project.new(project_params)
    if @project.save
      audit_create(@project, module_name: "projects")
      redirect_to projects_path
    end
  end
end
```

### Concern Best Practices

1. **Keep concerns focused** - One concern = one responsibility
2. **Name descriptively** - `Auditable`, `Searchable`, `Discardable`
3. **Document the interface** - Comment what methods are provided
4. **Avoid deep nesting** - Don't include concerns within concerns
5. **Test independently** - Create test classes that include the concern

---

## 2. Services

### What is a Service?

A **Service** (also called Service Object) is a plain Ruby class that encapsulates a single business operation or workflow. It follows the Single Responsibility Principle.

### When to Create a Service

| ✅ Create a Service When                    | ❌ Don't Create a Service When     |
| ------------------------------------------- | ---------------------------------- |
| Operation involves multiple steps           | Simple CRUD with no business logic |
| Interacting with external APIs              | Logic can be a simple method       |
| Complex business logic                      | It's just data formatting          |
| Need to coordinate multiple models          | Shared behavior (use Concern)      |
| Operation needs to be testable in isolation | View-related logic (use Helper)    |
| Callbacks become too complex                |                                    |

### Why Use Services?

1. **Single Responsibility** - One service = one operation
2. **Testability** - Easy to unit test in isolation
3. **Reusability** - Call from controllers, jobs, rake tasks
4. **Fat Models/Controllers** - Extract complexity out
5. **Explicit Dependencies** - Clear inputs and outputs

### Service Structure

**Location**: `app/services/`

**Naming Convention**: `<Noun><Verb>Service` or `<Verb><Noun>Service`

- `UserRegistrationService`
- `IconFileService`
- `PaymentProcessorService`
- `ReportGeneratorService`

### Service Pattern

```ruby
# app/services/application_service.rb (optional base class)
class ApplicationService
  def self.call(...)
    new(...).call
  end
end
```

```ruby
# app/services/user_registration_service.rb
class UserRegistrationService < ApplicationService
  def initialize(params, invited_by: nil)
    @params = params
    @invited_by = invited_by
  end

  def call
    ActiveRecord::Base.transaction do
      create_user
      assign_default_role
      send_welcome_email
      log_registration
    end

    Result.new(success: true, user: @user)
  rescue StandardError => e
    Result.new(success: false, error: e.message)
  end

  private

  def create_user
    @user = User.create!(@params)
  end

  def assign_default_role
    @user.update!(role: Role.find_by(name: "member"))
  end

  def send_welcome_email
    UserMailer.welcome(@user).deliver_later
  end

  def log_registration
    AuditLog.log(action: "register", user: @user)
  end

  # Simple result object
  Result = Struct.new(:success, :user, :error, keyword_init: true) do
    def success?
      success
    end
  end
end

# Usage:
result = UserRegistrationService.call(user_params, invited_by: current_user)
if result.success?
  redirect_to users_path, notice: "User created!"
else
  flash[:alert] = result.error
  render :new
end
```

### Service Examples

#### Example 1: IconFileService (Simple)

```ruby
# app/services/icon_file_service.rb
class IconFileService
  def initialize(record, attachment_name: :icon_file)
    @record = record
    @attachment_name = attachment_name
  end

  def handle_icon_change(params)
    return false unless @record.respond_to?(@attachment_name)

    if switching_to_bootstrap?(params) || removing_icon?(params)
      purge_icon_file
      true
    else
      false
    end
  end

  def purge_icon_file
    attachment.purge if icon_attached?
  end

  def icon_attached?
    attachment&.attached?
  rescue StandardError
    false
  end

  private

  def attachment
    @record.public_send(@attachment_name)
  end

  def switching_to_bootstrap?(params)
    params[:icon_type] == "bootstrap" && icon_attached?
  end

  def removing_icon?(params)
    params[:remove_icon_file] == "1"
  end
end
```

#### Example 2: ReportExportService (Complex)

```ruby
# app/services/report_export_service.rb
class ReportExportService
  FORMATS = %w[csv xlsx pdf].freeze

  def initialize(report, format:, user:)
    @report = report
    @format = format
    @user = user
    validate_format!
  end

  def call
    data = fetch_report_data
    file = generate_file(data)
    upload_to_storage(file)
    notify_user

    Result.new(success: true, download_url: @download_url)
  rescue StandardError => e
    Rails.logger.error("Report export failed: #{e.message}")
    Result.new(success: false, error: e.message)
  end

  private

  def validate_format!
    raise ArgumentError, "Invalid format" unless FORMATS.include?(@format)
  end

  def fetch_report_data
    @report.generate_data(user: @user)
  end

  def generate_file(data)
    case @format
    when "csv"  then CsvGenerator.new(data).generate
    when "xlsx" then ExcelGenerator.new(data).generate
    when "pdf"  then PdfGenerator.new(data).generate
    end
  end

  def upload_to_storage(file)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: "#{@report.name}_#{Time.current.to_i}.#{@format}"
    )
    @download_url = Rails.application.routes.url_helpers.rails_blob_url(blob)
  end

  def notify_user
    ReportMailer.export_ready(@user, @download_url).deliver_later
  end

  Result = Struct.new(:success, :download_url, :error, keyword_init: true) do
    def success?
      success
    end
  end
end
```

### Service Best Practices

1. **One public method** - Typically `call` or `execute`
2. **Return a result object** - Don't return `true/false`, return structured data
3. **Fail fast** - Validate inputs in constructor
4. **Use transactions** - Wrap multi-step operations
5. **Handle errors gracefully** - Catch and return meaningful errors
6. **Inject dependencies** - Pass dependencies, don't hardcode
7. **Keep services stateless** - Don't store state between calls

---

## 3. Helpers

### What is a Helper?

A **Helper** is a module that provides methods for use in views (and sometimes controllers). Helpers are for presentation logic—formatting, generating HTML, and display decisions.

### When to Create a Helper

| ✅ Create a Helper When       | ❌ Don't Create a Helper When |
| ----------------------------- | ----------------------------- |
| Formatting data for display   | Business logic                |
| Generating HTML snippets      | Database queries              |
| Conditional display logic     | Complex operations            |
| Reusable view components      | Multi-step processes          |
| Date/currency/text formatting | External API calls            |

### Why Use Helpers?

1. **Clean Views** - Keep ERB templates simple
2. **DRY** - Reuse presentation logic
3. **Testability** - Test view logic in isolation
4. **Separation of Concerns** - Views shouldn't have business logic

### Helper Structure

**Location**: `app/helpers/`

**Naming Convention**: `<Model>Helper` or `<Feature>Helper`

- `ApplicationHelper` - Global helpers
- `ProjectsHelper` - Project-specific helpers
- `FormattingHelper` - Formatting utilities

### Helper Types

#### Model-Specific Helper

```ruby
# app/helpers/projects_helper.rb
module ProjectsHelper
  DEFAULT_ICON = "bi-folder"

  # Render project icon (custom SVG or Bootstrap)
  def project_icon(project, size: "1em", css_class: "me-2")
    if project_has_custom_icon?(project)
      render_custom_icon(project, size: size, css_class: css_class)
    else
      render_bootstrap_icon(project.icon, css_class: css_class)
    end
  end

  def project_has_custom_icon?(project)
    project.icon_file.attached?
  rescue StandardError
    false
  end

  def show_svg_section?(project)
    project.persisted? && project_has_custom_icon?(project)
  end

  def initial_icon_type(project)
    show_svg_section?(project) ? "svg" : "bootstrap"
  end

  private

  def render_custom_icon(project, size:, css_class:)
    image_tag(
      rails_blob_path(project.icon_file, disposition: :inline, only_path: true),
      class: "project-custom-icon #{css_class}".strip,
      style: "width: #{size}; height: #{size}; vertical-align: -0.125em;",
      alt: "#{project.name} icon"
    )
  end

  def render_bootstrap_icon(icon_class, css_class:)
    safe_icon = sanitize_bootstrap_icon(icon_class)
    tag.i(class: "bi #{safe_icon} #{css_class}".strip)
  end

  def sanitize_bootstrap_icon(icon_class)
    raw_icon = icon_class.to_s.strip
    return DEFAULT_ICON if raw_icon.blank?
    raw_icon.match?(/\Abi-[\w-]+\z/) ? raw_icon : DEFAULT_ICON
  end
end
```

#### Application-Wide Helper

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  # Format datetime for display
  def format_datetime(datetime, format = :short)
    return "-" if datetime.blank?

    case format
    when :short     then datetime.strftime("%Y-%m-%d %H:%M")
    when :long      then datetime.strftime("%B %d, %Y at %I:%M %p")
    when :date_only then datetime.strftime("%Y-%m-%d")
    else datetime.to_s
    end
  end

  # Badge class for status
  def status_badge_class(status)
    case status.to_s.downcase
    when "active"   then "success"
    when "inactive" then "secondary"
    when "pending"  then "warning"
    else "secondary"
    end
  end

  # Render status badge
  def status_badge(status)
    tag.span(status.humanize, class: "badge bg-#{status_badge_class(status)}")
  end

  # Safe URL validation
  def safe_url(url)
    return nil if url.blank?
    uri = URI.parse(url)
    %w[http https].include?(uri.scheme) ? url : nil
  rescue URI::InvalidURIError
    nil
  end
end
```

#### Formatting Helper

```ruby
# app/helpers/formatting_helper.rb
module FormattingHelper
  # Format currency
  def format_currency(amount, currency: "USD")
    return "-" if amount.nil?
    number_to_currency(amount, unit: currency_symbol(currency))
  end

  # Format percentage
  def format_percentage(value, precision: 1)
    return "-" if value.nil?
    number_to_percentage(value, precision: precision)
  end

  # Format file size
  def format_file_size(bytes)
    return "-" if bytes.nil?
    number_to_human_size(bytes)
  end

  # Truncate with tooltip
  def truncate_with_tooltip(text, length: 50)
    return "" if text.blank?
    return text if text.length <= length

    tag.span(truncate(text, length: length),
             title: text,
             data: { bs_toggle: "tooltip" })
  end

  private

  def currency_symbol(currency)
    { "USD" => "$", "EUR" => "€", "GBP" => "£", "IDR" => "Rp" }[currency] || "$"
  end
end
```

### Helper Best Practices

1. **Keep helpers focused** - One helper per model/feature
2. **No database queries** - Helpers receive data, don't fetch it
3. **No side effects** - Don't modify state
4. **Return strings/HTML** - Output should be renderable
5. **Use `tag` helper** - Prefer `tag.div` over `content_tag`
6. **Mark private methods** - Only expose what views need
7. **Test thoroughly** - Helpers are easy to test

---

## Comparison Summary

| Aspect       | Concern               | Service              | Helper            |
| ------------ | --------------------- | -------------------- | ----------------- |
| **Location** | `app/*/concerns/`     | `app/services/`      | `app/helpers/`    |
| **Purpose**  | Shared behavior       | Business operations  | View presentation |
| **Used In**  | Models/Controllers    | Anywhere             | Views (primarily) |
| **Pattern**  | Mixin (include)       | Object instantiation | Module methods    |
| **State**    | Stateless             | Can be stateful      | Stateless         |
| **Testing**  | Include in test class | Unit test directly   | Helper test       |
| **Returns**  | Varies                | Result object        | String/HTML       |

### Code Location Decision

```
┌────────────────────────────────────────────────────────────────┐
│                        Your Code                                │
└────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│    Model      │     │  Controller   │     │     View      │
│               │     │               │     │               │
│ • Validations │     │ • Auth        │     │ • Display     │
│ • Associations│     │ • Params      │     │ • Formatting  │
│ • Scopes      │     │ • Responses   │     │ • HTML        │
│ • Callbacks   │     │ • Routing     │     │               │
└───────────────┘     └───────────────┘     └───────────────┘
        │                     │                     │
        │ Shared?             │ Shared?             │ Shared?
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│Model Concern  │     │Ctrl Concern   │     │    Helper     │
└───────────────┘     └───────────────┘     └───────────────┘

        │                     │
        │ Complex Operation?  │ Complex Operation?
        ▼                     ▼
        └──────────┬──────────┘
                   ▼
           ┌───────────────┐
           │    Service    │
           └───────────────┘
```

---

## Real-World Examples from This Project

### 1. Auditable (Concern)

**Why Concern?**

- Used in 5+ controllers (Projects, Companies, Users, Roles, Dashboards)
- Same audit logging pattern everywhere
- No complex business logic, just shared behavior

**File**: `app/controllers/concerns/auditable.rb`

### 2. IconFileService (Service)

**Why Service?**

- Handles icon type switching logic
- Could be reused for other models with icon attachments
- Encapsulates Active Storage operations
- Single responsibility: manage icon files

**File**: `app/services/icon_file_service.rb`

### 3. ProjectsHelper (Helper)

**Why Helper?**

- Renders icons in views (presentation)
- Formats Bootstrap icons or custom SVG
- Used in sidebar, forms, and lists
- No business logic, just display

**File**: `app/helpers/projects_helper.rb`

---

## Checklist for New Code

### Before Writing Code, Ask:

- [ ] Will this code be used in multiple places?
  - **Yes** → Consider Concern or Service
  - **No** → Keep in model/controller

- [ ] Is it shared model behavior (validations, scopes, callbacks)?
  - **Yes** → Model Concern

- [ ] Is it shared controller behavior (auth, logging, response handling)?
  - **Yes** → Controller Concern

- [ ] Is it a complex operation with multiple steps?
  - **Yes** → Service

- [ ] Does it interact with external APIs or services?
  - **Yes** → Service

- [ ] Is it formatting or display logic for views?
  - **Yes** → Helper

- [ ] Can it be tested in isolation?
  - Services and Helpers are easiest to test
  - Concerns require a host class

---

## File Templates

### Concern Template

```ruby
# app/models/concerns/feature_name.rb
# frozen_string_literal: true

# Description of what this concern provides.
#
# Usage:
#   class MyModel < ApplicationRecord
#     include FeatureName
#   end
#
module FeatureName
  extend ActiveSupport::Concern

  included do
    # Callbacks, scopes, validations here
  end

  class_methods do
    # Class methods here
  end

  # Instance methods here
end
```

### Service Template

```ruby
# app/services/action_name_service.rb
# frozen_string_literal: true

# Description of what this service does.
#
# Usage:
#   result = ActionNameService.call(params)
#   if result.success?
#     # handle success
#   else
#     # handle failure
#   end
#
class ActionNameService
  Result = Struct.new(:success, :data, :error, keyword_init: true) do
    def success? = success
    def failure? = !success
  end

  def self.call(...)
    new(...).call
  end

  def initialize(params)
    @params = params
  end

  def call
    # Implementation
    Result.new(success: true, data: result_data)
  rescue StandardError => e
    Result.new(success: false, error: e.message)
  end

  private

  attr_reader :params
end
```

### Helper Template

```ruby
# app/helpers/feature_helper.rb
# frozen_string_literal: true

# Helper methods for [feature] views.
#
module FeatureHelper
  # Renders [something]
  # @param record [Model] the record to render
  # @param options [Hash] additional options
  # @return [String] HTML string
  def render_something(record, **options)
    # Implementation
  end

  private

  def private_helper_method
    # Implementation
  end
end
```

---

## Summary

| Use This    | When You Need To                                     |
| ----------- | ---------------------------------------------------- |
| **Concern** | Share behavior across multiple models or controllers |
| **Service** | Encapsulate complex business operations              |
| **Helper**  | Format data and generate HTML for views              |

**Remember**: When in doubt, start simple. You can always extract to a Concern, Service, or Helper later when the need becomes clear. Premature abstraction is worse than duplication.
