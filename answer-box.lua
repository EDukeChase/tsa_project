-- answer-box.lua
-- This filter finds a Div with the class "answer-box" and wraps its
-- content in a custom LaTeX environment called 'answerbox'.

function Div(el)
  -- Check if the element is a Div and has the "answer-box" class
  if el.classes:includes("answer-box") then
    -- Convert the content of the Div to raw LaTeX
    local content_latex = pandoc.write(pandoc.Pandoc(el.content), 'latex')
    
    -- Create a raw LaTeX block with our custom environment
    local new_content = '\\begin{answerbox}\n' .. content_latex .. '\n\\end{answerbox}'
    
    -- Return the new LaTeX block to replace the original Div
    return {pandoc.RawBlock('latex', new_content)}
  end
end