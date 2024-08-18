
Here is my wip for defining the runtime rules.

Some details need to be figured out.

- For every run we walk through the graph and run process_node on the current path.
  However on reruns with stored state details/state for nodes may already present. (this is related to the option of applyin gand reverting to tags when running graphs to persiste astate artifcats.
  So in process_node we would want to check for existing state (if state dependent actions are present) and load that per node state
  mutate if it necessary (if expired, etc.) and proceed. Further we need to communicate/spread state invalidation to subsequent nodes if they are impacted
  by the change. So as each node state is stored in addition to the state itself we will want to store a digest/key that indicates
  the toggles that impact the cached state. This implies we need to expose global state as well as per node state. For example current date. List of memories,
  api failure state to avoid using a specific model, etc.
  
  Further as we process each node we want to register it to state. Storing not only the node itself but artifacts like rules that will build settings, effective messages, etc.
  Thus as we apply nodes to state we need to determine
    - do we already have a rule entry for the node.
    - if we do is the rule entry still valid (has the node changed, has the state changed, etc.)
      a good example would be a rule that picks temperature from grid search.
      we can either roll back the rule set on each run or indicate as part of the generated rule that the value is dynamic/has changed since the last run.
    - I believe the most straight forward approach for the time being will be to retain node/link/rule state/lookup but clear the sequence on every run.
      as we walk over the graph and rebuild the rules we check if the rule is still valid and if not we rebuild it. We use the rule key/finger print to do this.
      and then deal with invalidating stored values attached to rules.
      (rules themselves should indicate which setting they alter, and which setting they depend on).
    - For MVP we will brute force things nad rebuild from scratch, and make the optimized flow a branch by abstraction feature flag that impacts how state is
      refreshed during a run/report.
  
- Going from a node artifacts. A node may have multiple artifacts. A node may have a rule that generates a setting, a rule that generates a message, a rule that generates a tool, etc.
  A single node may generate multiple messages, und so forth.
  
  There is an optimization item here in the future to avoid regenerating the same artifacts on every run but essentially  during process_node
  nodes should grab stored state, invalidate where appropriate and then inject into state a set of messages and rules.
  
  process_node
    --> get_stored_state for node
    --> get global state/references required to process
    --> determine if invalidation has occured (so nodes generate a thumbprint and store in state.)
        after fetching stored node and global state we check if this thumbprint has changed.
        if the thumbprint has changed we replace stored rules and messages with changes,
        otherwise we return the previous state (rules and messages).
  
    How this works in practice. Lets say we have a node that picks the best model for planning.
    A component of the best model for planning may be type of planning (problem solving, riddle solving, etc.)
    An advanced picker may use inference and chant context to pick the best model. This can be done in stages however:
    are we answering a riddle, are we x, etc. w model generates a boolean list of flags.
    The flags are only updated if the message thread to current position has changed and the generated rules are static based on whatever the flags are.
    And the flags only impact selectors/constraints but not the rule itself as the rule simply states prepare features, pick best model per features plus other constraints.
    So the rule does not need to be changed if the flags changed but it output will change so derived rules/constraints will be impacted if the list changes.
    
  
    # MVP
    Again while we will impelement /stub caching/intelligent checking we will for the prototype rebuild on every run.

    ## MVP TODOS
    - [ ] process node
    - [ ] reference stored state/check for invalidations and update state etc. (global and node specific)
    - [ ] apply node to seuquence
    - [ ] generate rules/artifacts: (messages , rules, etc.)
    - [ ] only on demand (like if a node requests current model to run inference) do we apply rules (so far in sequence) to preapare mdoels/settings.
    - [ ] ignore caching/optimizations for now.
    
     ### Flow
        process_node fetches state, updates state for node and any artifcates and appends node.
        (Somewhere in process_node or a unique method tto keep process_node generic) after updating state/artifacts we expand the node into any rules and messages and these are aadded to sequence.

        Finally as needed when we reach inference points we build effective settings, etc.





<style>
div.details { 
    text-align: left;
    border-top: dashed 1px gray;
    padding-top: 5px;
    margin-top: 5px;
}

div.details br:first-child {
    display: none;
}

</style>

```mermaid 
flowchart TD

    EXTERNAL{{"EXTERNAL DATA"}}
    --> AGENT_META_DATA["Agent Meta Data"]


    START@{ shape: start} 
    --> SYSTEM_MSG 
    --> USER_MSG 
    --> COMPOSITE_MSG
    --> REVIEW_DOCUMENT

    subgraph SYSTEM_MSG[System Message]
        SM_PROMPT["
        **System Prompt**
        <div class="details">
        Core Instructions.
        Follow NPL Conventions. etc.
        </div>
        "]

        SM_NPL["
        **NPL Prompt**
        <div class="details">
        1. NPL Prompt Conventions.
        2. NPL Declarations.
        &nbsp;&nbsp;2.1  Author Agent
        &nbsp;&nbsp;2.2  Grading Service
        &nbsp;&nbsp;2.3  Copy Editor Service
        </div>
        "]

        SM_CONTEXT["
        **System Context**
        <div class="details">
        1. User Profile.
        2. User Instructions.
        3. Working Relantship
        and details from memory.
        </div>
        "]

        SM_MINDERS["
        **System Minders**
        <div class="details">
        Reinforcing instructions based on past behavior/model quirks to correct behavior.
        </div>
        "]
    end

    USER_MSG["
    **User Message**
    <div class="details">
    Initial Request for a Document
    </div>
    "]


    subgraph COMPOSITE_MSG["Composite Message"]
        direction LR

        AGENT_META_DATA1["Agent Meta Data"] -->
        AUTHER_AGENT["
        **Author Agent**:
        <div class="details">Full Definition of Author Agent</div>
        "] -->

        GENERATE_CONTEXT["
        **Context**:
        <div class="details">
        Scan memory database for details relevent to request
        </div>
        "] -->

        PLAN_CONTEXT["
        **Planning**:
        <div class="details">
        State Assumptions. Plan how to proceed.
        </div>
        "] -->

        DRAFT_OUTLINE["
        **Draft Outline**:
        <div class="details">
        Structure Document.
        </div>
        "] -->

    
        WRITE_SECTION["
        **Draft Outline**:
        <div class="details">
        Write Sections (one at a time to control length.)
        </div>
        "] --> 

        CONTINUE@{ shape: diamond, label: "Decision" }
        CONTINUE --> |finished?| DOCUMENT_ARTIFACT
        CONTINUE --> |remaining sections| WRITE_SECTION

        DOCUMENT_ARTIFACT["
        **Store Draft Artifact**:
        <div class="details">
        Now that initial draft is complte store as draft. 
        </div>
        "]

    end


    

    subgraph REVIEW_DOCUMENT["Review Document"]
        DOCUMENT_ARTIFACT2["Draft Artifact"] 
        --> BEGIN_REVIEW@{ shape: fork }
        --> AUTHOR_AGENT_1_1 & GRADE_AGENT_1_1 & EDITOR_AGENT_1_1

        AGENT_META_DATA2["Agent Meta Data"] -->
        AUTHOR_AGENT_1_1["
        **Author Agent**:
        <div class="details">Full Definition of Author Agent</div>
        "]  --> 
        AUTHOR_AGENT_1_2["Self Assess/Review Work"] --> AUTHOR_AGENT_1_3["`Save Draft with inline comments and suggested changes.`"] --> 
        END_REVIEW


        AGENT_META_DATA2 ---> 
        GRADE_AGENT_1_1["
        **GRADE Agent**:
        <div class="details">Full Definition of Grade Agent</div>
        "] -->
        GRADE_AGENT_1_2["Grader: Grade By Rubix"] -->
        GRADE_AGENT_1_3["Save Draft with Rubix and inline comments added"] --> 
        END_REVIEW


        AGENT_META_DATA2 ---> 
        EDITOR_AGENT_1_1["
        **GRADE Agent**:
        <div class="details">Full Definition of Grade Agent</div>
        "] -->
        EDITOR_AGENT_1_2["Copy Editor Review"] -->
        EDITOR_AGENT_1_3["Save Draft with inline comments and suggested changes"] --> 
        END_REVIEW
        
        
        END_REVIEW@{ shape: fork }
        --> MERGE_ARTIFACTS["Merge Author, Grader and Editor Documents"]
    end



       


    REVIEW_DOCUMENT -->
    AUTHOR_AGENT_2_1["Reflect on combined artifact, and prepare notes to adjust self instructions for generating content"]  -->
    AUTHOR_AGENT_2_2["Decide on desired changes and resources for Collab Step."] -->
    AUTHOR_AGENT_2_3["Prepare Agenda"]  -->
      GOOD_ENOUGH@{ shape: diamond, label: "Decision" }
      
  
    AUTHOR_AGENT_2_1 
    --> |Update|AGENT_META_DATA3["Agent Meta Data"] 
    

GOOD_ENOUGH --> |yes|END
GOOD_ENOUGH --> |no|COLLAB


    subgraph COLLAB["Team Collab"]
        
        TEAM["Generate Team Profiles"] --> 
        BEGIN_PRELIM@{ shape: fork }

            BEGIN_PRELIM -->
            REVIEW_DOC["REVIEW_DOC"] -->
        BEGIN_PR@{ shape: fork }

            BEGIN_PR -->
            R1_1["REVIEWER 1"] -->
            R1_2["Tailored Feedback Request"] -->
            R1_3["Review and add Comments to Artifact"] --> END_PR

            BEGIN_PR -->
            R2_1["REVIEWER 2"] -->
            R2_2["Tailored Feedback Request"] -->
            R2_3["Review and add Comments to Artifact"] --> END_PR

            BEGIN_PR -->
            RN_1["...REVIEWER N"] -->
            RN_2["Tailored Feedback Request"] -->
            RN_3["Review and add Comments to Artifact"] --> END_PR

        END_PR@{ shape: fork }
        --> COMBINE_PR["Merge Artifacts and Summarize"]
        --> END_PRELIM



            BEGIN_PRELIM -->
            REVIEW_DOC_2["FACT_CHECK_DOC"] -->
        BEGIN_FR@{ shape: fork }

            BEGIN_FR -->
            F1_1["Statement 1"] -->
            F1_2["Verify/Research"] -->
            F1_3["Review and add Comments to Artifact"] --> END_FR

            BEGIN_FR -->
            F2_1["Statement 2"] -->
            F2_2["Verify/Reaserch"] -->
            F2_3["Review and add Comments to Artifact"] --> END_FR

            BEGIN_FR -->
            FN_1["...STATEMENT N"] -->
            FN_2["Verify/Research"] -->
            FN_3["Review and add Comments to Artifact"] --> END_FR

        END_FR@{ shape: fork }
        --> COMBINE_FR["Merge Artifacts and Summarize"]
        --> END_PRELIM


            BEGIN_PRELIM -->
            REVIEW_DOC_3["Test Code Samples/Equations"] -->
            BEGIN_TR@{ shape: fork }
T
            BEGIN_TR -->
            T1_1["Example 1"] -->
            T1_2["Test Code"] -->
            T1_3["Review and add Comments to Artifact"] --> END_TR

            BEGIN_TR -->
            T2_1["Statement 2"] -->
            T2_2["Test Code"] -->
            T2_3["Review and add Comments to Artifact"] --> END_TR

            BEGIN_TR -->
            TN_1["...STATEMENT N"] -->
            TN_2["Test Code"] -->
            TN_3["Review and add Comments to Artifact"] --> END_TR

        END_TR@{ shape: fork }
        --> COMBINE_TR["Merge Artifacts and Summarize"]
        --> END_PRELIM

        END_PRELIM@{ shape: fork }

        --> COMBINE_PRELIM["Merge Doc Notes,Items"]
        --> 

               BEGIN_RR@{ shape: fork }


            BEGIN_RR -->
            RR_1_1["REVIEWER 1"] -->
            RR_1_2["Add comments to other reviewer comments."] --> END_RR

            BEGIN_RR -->
            RR_2_1["REVIEWER 2"] -->
            RR_2_2["Add comments to other reviewer comments."] --> END_RR

            BEGIN_RR -->
            RR_N_1["...REVIEWER N"] -->
            RR_N_2["Add comments to other reviewer comments."] --> END_RR


               END_RR@{ shape: fork }
 
        --> AUTHOR_3_1["Review and prepare Agenda for Team Collab"]


        --> DISCUSSION["Collab Chat Room: Discuss Document, Prepare Revisions for Review, vote, change outline"]

        --> KEY_POINTS["Prepare Key Takeaway and action plan for waht to change in document, comment on notes what resolution will be applied"]

        --> REVISE["Passing Agenda and annoted Document prepare additional revision (using same loop process as before)"]

    end
 

   
COLLAB ----------------------> REVIEW_DOCUMENT2["Return to Review Step"]




    END@{ shape: start} 



```

