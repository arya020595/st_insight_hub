# Project Icon Upload Feature

## Overview

This document describes the custom SVG icon upload feature for projects, which allows users to choose between Bootstrap Icons or custom SVG files for project sidebar icons.

## Background

### Problem Statement

Previously, projects only supported Bootstrap Icons specified by class name (e.g., `bi-folder`). Users requested the ability to upload custom SVG icons for better branding and visual distinction between projects.

### Solution

We implemented a toggle-based UI that allows users to:

1. **Bootstrap Icon**: Enter a Bootstrap icon class name with live preview
2. **Custom SVG**: Upload an SVG file (max 100KB) with validation

The system automatically handles switching between icon types, including cleanup of old attachments.

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         Controller                               │
│  ProjectsController                                              │
│  ├── includes Auditable (concern)                               │
│  └── uses IconFileService (service)                             │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    Service      │  │    Concern      │  │     Helper      │
│ IconFileService │  │   Auditable     │  │ ProjectsHelper  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Active Storage │  │   AuditLog      │  │      View       │
│   (icon_file)   │  │    Model        │  │   Rendering     │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## Services

### IconFileService

**Location**: `app/services/icon_file_service.rb`

**Purpose**: Manages icon file attachments for any Active Storage-enabled model. Handles icon type switching logic and cleanup operations.

#### Constructor

```ruby
IconFileService.new(record, attachment_name: :icon_file)
```

| Parameter         | Type                 | Default      | Description                           |
| ----------------- | -------------------- | ------------ | ------------------------------------- |
| `record`          | `ActiveRecord::Base` | required     | Record with Active Storage attachment |
| `attachment_name` | `Symbol`             | `:icon_file` | Name of the attachment attribute      |

#### Methods

##### `handle_icon_change(params)`

Handles icon type change based on form params. Purges existing icon file when switching to Bootstrap icon or when explicitly removed.

```ruby
# In controller
def update
  IconFileService.new(@project).handle_icon_change(project_params)
  @project.update(filtered_params)
end
```

**Parameters**:

- `params` - Hash or ActionController::Parameters containing `icon_type` and/or `remove_icon_file`

**Returns**: `Boolean` - `true` if any change was made

##### `switching_to_bootstrap?(params)`

Check if switching from custom icon to Bootstrap icon.

```ruby
service = IconFileService.new(@project)
if service.switching_to_bootstrap?(params)
  # Handle Bootstrap switch
end
```

##### `removing_icon?(params)`

Check if user requested to remove the icon file.

```ruby
service = IconFileService.new(@project)
if service.removing_icon?(params)
  # Handle removal
end
```

##### `purge_icon_file`

Purge the attached icon file directly.

```ruby
IconFileService.new(@project).purge_icon_file
```

##### `icon_attached?`

Check if icon file is currently attached.

```ruby
IconFileService.new(@project).icon_attached?
# => true or false
```

#### Usage Examples

**Basic Usage**:

```ruby
class ProjectsController < ApplicationController
  def update
    # Handle icon switching before update
    IconFileService.new(@project).handle_icon_change(project_params)

    if @project.update(filtered_project_params)
      redirect_to projects_path
    else
      render :edit
    end
  end
end
```

**With Custom Attachment Name**:

```ruby
# For a model with `logo` attachment instead of `icon_file`
class CompaniesController < ApplicationController
  def update
    IconFileService.new(@company, attachment_name: :logo).handle_icon_change(company_params)
    @company.update(company_params)
  end
end
```

---

## Concerns

### Auditable

**Location**: `app/controllers/concerns/auditable.rb`

**Purpose**: Provides a simplified DSL for audit logging in controllers. Automatically captures before/after states for CRUD operations.

#### Methods

##### `audit_create(record, module_name:, summary: nil)`

Log a create action for a record.

```ruby
def create
  @project = Project.new(project_params)

  if @project.save
    audit_create(@project, module_name: "projects")
    redirect_to projects_path
  end
end
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `record` | `ActiveRecord::Base` | Yes | The created record |
| `module_name` | `String` | Yes | Module/section name for categorization |
| `summary` | `String` | No | Custom summary (auto-generated if nil) |

##### `audit_update(record, module_name:, summary: nil, &block)`

Log an update action, capturing before/after state automatically.

```ruby
def update
  updated = audit_update(@project, module_name: "projects") do
    @project.update(project_params)
  end

  if updated
    redirect_to projects_path
  else
    render :edit
  end
end
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `record` | `ActiveRecord::Base` | Yes | The record to update |
| `module_name` | `String` | Yes | Module/section name |
| `summary` | `String` | No | Custom summary |
| `block` | `Block` | Yes | Block that performs the update |

**Returns**: `Boolean` - Result of the update operation

##### `audit_delete(record, module_name:, summary: nil)`

Log a delete/discard action for a record.

```ruby
def destroy
  @project.discard
  audit_delete(@project, module_name: "projects")
  redirect_to projects_path
end
```

##### `audit_restore(record, module_name:, summary: nil)`

Log a restore/undiscard action for a record.

```ruby
def restore
  @project.undiscard
  audit_restore(@project, module_name: "projects")
  redirect_to projects_path
end
```

#### Usage Examples

**Basic Controller with Auditable**:

```ruby
class ProjectsController < ApplicationController
  include Auditable

  def create
    @project = Project.new(project_params)

    if @project.save
      audit_create(@project, module_name: "projects")
      redirect_to projects_path, notice: "Created!"
    else
      render :new
    end
  end

  def update
    updated = audit_update(@project, module_name: "projects") do
      @project.update(project_params)
    end

    if updated
      redirect_to projects_path, notice: "Updated!"
    else
      render :edit
    end
  end

  def destroy
    @project.discard
    audit_delete(@project, module_name: "projects")
    redirect_to projects_path, notice: "Deleted!"
  end
end
```

**With Custom Summary**:

```ruby
audit_create(@user,
  module_name: "user_management",
  summary: "Admin created new user: #{@user.email}"
)
```

---

## Helpers

### ProjectsHelper

**Location**: `app/helpers/projects_helper.rb`

**Purpose**: Provides helper methods for rendering project icons in views.

#### Constants

| Constant                 | Value             | Description                                    |
| ------------------------ | ----------------- | ---------------------------------------------- |
| `DEFAULT_ICON`           | `"bi-folder"`     | Default Bootstrap icon when none specified     |
| `BOOTSTRAP_ICON_PATTERN` | `/\Abi-[\w-]+\z/` | Regex pattern for valid Bootstrap icon classes |

#### Methods

##### `project_icon(project, size:, css_class:)`

Renders a project icon - either custom SVG or Bootstrap icon.

```erb
<%= project_icon(@project) %>
<%= project_icon(@project, size: "2em", css_class: "text-primary") %>
```

**Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `project` | `Project` | required | The project to render icon for |
| `size` | `String` | `"1em"` | CSS size for custom icons |
| `css_class` | `String` | `"me-2"` | Additional CSS classes |

**Returns**: `String` - HTML for the icon (img tag or i tag)

##### `project_has_custom_icon?(project)`

Check if project has a valid attached custom icon.

```erb
<% if project_has_custom_icon?(@project) %>
  <span>Using custom icon</span>
<% end %>
```

##### `show_svg_section?(project)`

Determines if the form should show SVG section by default.

```erb
<div style="<%= 'display: none;' unless show_svg_section?(@project) %>">
  <!-- SVG upload section -->
</div>
```

##### `initial_icon_type(project)`

Returns the initial icon type for the form ('svg' or 'bootstrap').

```erb
<%= f.hidden_field :icon_type, value: initial_icon_type(@project) %>
```

##### `sanitize_bootstrap_icon(icon_class)`

Returns a sanitized Bootstrap icon class.

```ruby
sanitize_bootstrap_icon("bi-folder")     # => "bi-folder"
sanitize_bootstrap_icon("invalid")       # => "bi-folder" (default)
sanitize_bootstrap_icon("bi bi-star")    # => "bi-star"
```

---

## Model Configuration

### Project Model

**Location**: `app/models/project.rb`

The Project model includes Active Storage attachment and validation:

```ruby
class Project < ApplicationRecord
  # Constants
  MAX_ICON_FILE_SIZE = 100.kilobytes
  VALID_STATUSES = %w[active inactive].freeze
  DEFAULT_ICON = "bi-folder"

  # Active Storage attachment
  has_one_attached :icon_file

  # Validation
  validate :icon_file_format, if: -> { icon_file.attached? }

  # Helper methods
  def display_icon
    icon_file.attached? ? :custom : (icon.presence || DEFAULT_ICON)
  end

  def custom_icon?
    icon_file.attached?
  end

  private

  def icon_file_format
    validate_icon_content_type
    validate_icon_file_size
  end

  def validate_icon_content_type
    return if icon_file.content_type == "image/svg+xml"
    errors.add(:icon_file, "must be an SVG file")
  end

  def validate_icon_file_size
    return if icon_file.byte_size <= MAX_ICON_FILE_SIZE
    errors.add(:icon_file, "must be less than 100KB")
  end
end
```

---

## Frontend (Stimulus Controller)

### IconToggleController

**Location**: `app/javascript/controllers/icon_toggle_controller.js`

**Purpose**: Manages icon selection UI with live preview.

#### Targets

| Target               | Description                               |
| -------------------- | ----------------------------------------- |
| `bootstrapRadio`     | Radio button for Bootstrap icon selection |
| `svgRadio`           | Radio button for custom SVG selection     |
| `bootstrapSection`   | Container for Bootstrap icon input        |
| `svgSection`         | Container for SVG file upload             |
| `iconInput`          | Text input for Bootstrap icon class       |
| `iconPreview`        | Element to display Bootstrap icon preview |
| `fileInput`          | File input for SVG upload                 |
| `svgPreview`         | Container for SVG file preview            |
| `removeFileCheckbox` | Checkbox to remove existing SVG           |
| `iconTypeField`      | Hidden field to track selected icon type  |

#### Values

| Value             | Type    | Default       | Description                      |
| ----------------- | ------- | ------------- | -------------------------------- |
| `hasExistingFile` | Boolean | `false`       | Whether project has existing SVG |
| `defaultIcon`     | String  | `"bi-folder"` | Default Bootstrap icon class     |

#### Actions

| Action                   | Description                               |
| ------------------------ | ----------------------------------------- |
| `toggle`                 | Switch between Bootstrap and SVG sections |
| `previewBootstrapIcon`   | Update Bootstrap icon preview             |
| `previewSvgFile`         | Preview uploaded SVG file                 |
| `handleRemoveFileChange` | Handle remove checkbox change             |

---

## Active Storage Configuration

### Development & Production

**Location**: `config/environments/development.rb` and `config/environments/production.rb`

SVG files are configured to serve inline (not as downloads):

```ruby
# Allow SVG files to be served inline with correct content type
config.active_storage.content_types_to_serve_as_binary -= ["image/svg+xml"]
config.active_storage.content_types_allowed_inline += ["image/svg+xml"]
```

---

## Testing

### Test File

**Location**: `test/models/project_icon_test.rb`

**Test Cases**:

1. Create project with Bootstrap icon only
2. Create project with custom SVG icon
3. Update from Bootstrap icon to custom SVG
4. Update from custom SVG to Bootstrap icon (by removing SVG)
5. Update custom SVG with new custom SVG
6. Reject non-SVG file upload
7. Reject SVG file over 100KB
8. Default icon when none specified

Run tests:

```bash
bin/rails test test/models/project_icon_test.rb
```

---

## Migration Guide

### Adding Icon Upload to Another Model

1. **Add Active Storage attachment to model**:

```ruby
class Company < ApplicationRecord
  has_one_attached :logo

  validate :logo_format, if: -> { logo.attached? }

  private

  def logo_format
    unless logo.content_type == "image/svg+xml"
      errors.add(:logo, "must be an SVG file")
    end
  end
end
```

2. **Use IconFileService in controller**:

```ruby
class CompaniesController < ApplicationController
  def update
    IconFileService.new(@company, attachment_name: :logo).handle_icon_change(company_params)
    @company.update(company_params)
  end
end
```

3. **Create helper methods** (optional):

```ruby
module CompaniesHelper
  def company_logo(company, size: "2em")
    if company.logo.attached?
      image_tag(rails_blob_path(company.logo, disposition: :inline),
                style: "width: #{size}; height: #{size};")
    else
      tag.i(class: "bi bi-building")
    end
  end
end
```

---

## Changelog

| Date       | Change                                        |
| ---------- | --------------------------------------------- |
| 2026-02-10 | Initial implementation of SVG icon upload     |
| 2026-02-10 | Extracted IconFileService for reusability     |
| 2026-02-10 | Extracted Auditable concern for audit logging |
| 2026-02-10 | Created ProjectsHelper for icon rendering     |
