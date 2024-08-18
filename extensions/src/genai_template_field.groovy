// ------------------------------------------------------------------------------------------------
// Example Live Template Groovy script that:
//
// 1. Accesses the IntelliJ/JetBrains Editor via _editor.
// 2. Extracts lines above/below the current caret position.
// 3. Calls the OpenAI Chat Completion API with the extracted context.
// ------------------------------------------------------------------------------------------------

// Only needed if your environment supports @Grab and does not already have these libs on classpath:
@Grab('org.apache.httpcomponents:httpclient:4.5.13')
@Grab('org.apache.httpcomponents:httpcore:4.4.13')
@Grab('com.google.code.gson:gson:2.8.6')
@Grab(group='org.apache.ivy', module='ivy', version='2.5.0')
@Grab(group='com.openai', module='openai-java', version='0.8.0w')

// JetBrains/IntelliJ-specific imports:
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.editor.CaretModel
import com.intellij.openapi.editor.Document
import com.intellij.openapi.util.TextRange

// Apache HttpClient & JSON imports:
import org.apache.http.client.methods.HttpPost
import org.apache.http.impl.client.CloseableHttpClient
import org.apache.http.impl.client.HttpClients
import org.apache.http.entity.StringEntity
import com.google.gson.Gson


// openai
import com.openai.models.ChatCompletion;
import com.openai.models.ChatCompletionCreateParams;
import com.openai.models.ChatCompletionMessageParam;
import com.openai.models.ChatCompletionUserMessageParam;
import com.openai.models.ChatModel;

// ------------------------------------------------------------------------------------------------
// Main logic
// ------------------------------------------------------------------------------------------------

// 1) Check for OpenAI API key in environment
def openaiApiKey = System.getenv("OPENAI_API_KEY")
if (!openaiApiKey) {
    throw new IllegalStateException("ERROR: OPENAI_API_KEY not found in environment.")
}

// 2) Args
def fieldName = _1
def fieldInstructions = _2


// 3) Access the editor from the Live Template environment
if (!_editor) {
    throw new IllegalStateException("ERROR: _editor is null. Make sure this is run as a Live Template macro.")
}

Editor editor = _editor
CaretModel caretModel = editor.getCaretModel()
Document document = editor.getDocument()

// The entire file content as a String:
def docText = document.getText()

// Get the caret’s absolute character offset in the document:
def caretOffset = caretModel.getOffset()

// Slice the text before the caret:
def textBeforeCaret = docText.substring(0, caretOffset)

// Slice the text after (and including) the caret:
def textAfterCaret = docText.substring(caretOffset, docText.length())


def params = ChatCompletionCreateParams.builder()
        .messages(List.of(ChatCompletionMessageParam.ofChatCompletionUserMessageParam(ChatCompletionUserMessageParam.builder()
                .role(ChatCompletionUserMessageParam.Role.USER)
                .content(ChatCompletionUserMessageParam.Content.ofTextContent("Say this is a test"))
                .build())))
        .model(ChatModel.O1)
        .build();
ChatCompletion chatCompletion = client.chat().completions().create(params);




// 5) Create OpenAI ChatCompletion request
def chatRequest = new ChatCompletionRequest(
        model       : "gpt4o", // or "gpt-4", etc.
        temperature : 0.7,             // tweak as needed
        top_p       : 1.0,             // tweak as needed

        messages    : [
                [
                        role   : "system",
                        content: "You are a gpt copilot, generatte the requested json as requsted."
                ],
                [
                        role   : "user",
                        content: """\
Please generate code or text for the variable named "${variableName}" using the following instructions and context.

Instructions:
${instructions}

Lines Above:
${linesAboveText}

Lines Below:
${linesBelowText}
"""
                ]
        ]
)


"FUCK YOU"